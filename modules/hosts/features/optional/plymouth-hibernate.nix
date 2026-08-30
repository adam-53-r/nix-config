# A Plymouth splash while the hibernation image is written, and again while the
# resumed system takes the display back.
#
# Writing a 12G image takes long enough that a still desktop reads as a hang.
#
# Plymouth has no sleep mode of its own — plymouthd knows only --mode=boot and
# --mode=shutdown, and nixpkgs ships no sleep integration — so shutdown mode is
# borrowed here. It is the one built to come up over a session that is already
# running and then tear itself down again.
#
# The VT switch is not optional. There is one DRM master per device and the
# compositor holds it for as long as its VT is active, so plymouthd cannot draw
# until the session is switched away; nixpkgs never has to solve this because
# plymouth-quit-wait.service is ordered before the display manager, so the two
# are never on screen at once. Leaving the session's VT makes logind deactivate
# it and revoke the compositor's devices, and returning hands them back.
#
# Only the first moment is animated. Once the kernel freezes userspace
# plymouthd freezes with it and its last frame stays up until power is cut,
# which is the point: a splash stopped on a spinner still reads as work in
# progress where a stopped desktop does not. The same frozen daemon is restored
# with the image, so it covers the gap on the way back out too, between the
# initrd's plymouth going away with the resume kernel and the compositor
# repainting.
#
# Cheaper alternative if the VT handoff proves unreliable on some host: drop
# this module and put `hyprctl dispatch dpms off` in hypridle's
# before_sleep_cmd. A dark panel never looks stuck either, it just says less.
{
  flake.nixosModules.optionalPlymouthHibernate = {
    pkgs,
    lib,
    config,
    ...
  }: let
    plymouth = config.boot.plymouth.package;

    # Clear of logind's NAutoVTs range (1-6 by default), so switching here does
    # not spawn a getty, and clear of the VT display managers conventionally
    # take. The VT to come back to is read at runtime rather than assumed.
    splashVt = 8;
    stashedVt = "/run/plymouth-hibernate.vt";

    enter = pkgs.writeShellScript "plymouth-hibernate-enter" ''
      set -u
      ${pkgs.kbd}/bin/fgconsole >${stashedVt} 2>/dev/null || echo 1 >${stashedVt}
      ${pkgs.kbd}/bin/chvt ${toString splashVt}
      ${plymouth}/sbin/plymouthd --mode=shutdown --attach-to-session
      # Whether a message renders at all is up to the theme, and neither of
      # these is worth failing hibernation over.
      ${plymouth}/bin/plymouth show-splash || true
      ${plymouth}/bin/plymouth display-message --text="Hibernating" || true
    '';

    leave = pkgs.writeShellScript "plymouth-hibernate-leave" ''
      set -u
      ${plymouth}/bin/plymouth quit || true
      ${pkgs.kbd}/bin/chvt "$(cat ${stashedVt} 2>/dev/null || echo 1)"
    '';
  in {
    key = "mynix#nixosModules.optionalPlymouthHibernate";

    config = lib.mkIf config.boot.plymouth.enable {
      systemd.services.plymouth-hibernate = {
        description = "Show a Plymouth splash while hibernating";

        # suspend-then-hibernate reaches hibernation by starting this same
        # unit once HibernateDelaySec expires, so it is covered as well. Plain
        # suspend is not, and does not need to be.
        wantedBy = ["systemd-hibernate.service"];
        before = ["systemd-hibernate.service"];

        unitConfig = {
          # systemd-hibernate.service is itself DefaultDependencies=no; taking
          # the implicit ordering against basic.target and shutdown.target
          # here would risk a cycle for no benefit.
          DefaultDependencies = false;
          # This is what runs ExecStop, and it fires when
          # systemd-hibernate.service deactivates — which on a successful
          # hibernate is after the resume, not before the power cut. Same
          # shape nixpkgs gives its own sleep-actions unit.
          StopWhenUnneeded = true;
        };

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = enter;
          ExecStop = leave;
        };
      };
    };
  };
}
