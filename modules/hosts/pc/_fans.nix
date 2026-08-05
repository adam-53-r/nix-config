# MSI X870E fan control. The board's NCT6687-R has no in-tree driver, so the
# CPU and case fans are invisible to Linux and the BIOS curve runs them at
# ~52%/~69% at idle. nct6687d + fancontrol take them over.
#
# pwm1/fan1 = CPU, pwm2/fan2 = pump, pwm3/fan3 = System #1, pwm8/fan8 =
# System #6; headers 4-7 empty. The pump stays on the EC - fancontrol only
# drives the pwms listed below.
#
# At full load the CPU sits at 84C with its fan at 35% and 82C at 100%, so the
# curve holds the quiet floor until 85C rather than trade noise for 2C. The
# board's System temp doesn't move (52C under load), so the case fans key off
# the GPU edge temp instead - the 374W card is what heats this case. LACT
# still owns the GPU's own fan; this only reads its temperature.
{config, ...}: {
  boot = {
    extraModulePackages = [config.boot.kernelPackages.nct6687d];
    kernelModules = ["nct6687"];
    # The EC re-applies its own curve over plain pwm writes on the case headers
    # (the CPU header sticks either way); brute force writes all 7 curve points
    # instead, which it honours.
    extraModprobeConfig = ''
      options nct6687 msi_fan_brute_force=1
    '';
  };

  # 77 = 30%, 90 = 35%, 190 = 75%. hwmon numbering shifts between boots, so
  # fancontrol remaps the labels below via DEVPATH/DEVNAME.
  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=10
      DEVPATH=hwmon2=devices/pci0000:00/0000:00:01.1/0000:01:00.0/0000:02:00.0/0000:03:00.0 hwmon8=devices/platform/nct6687.2592
      DEVNAME=hwmon2=amdgpu hwmon8=nct6687
      FCTEMPS=hwmon8/pwm1=hwmon8/temp1_input hwmon8/pwm3=hwmon2/temp1_input hwmon8/pwm8=hwmon2/temp1_input
      FCFANS=hwmon8/pwm1=hwmon8/fan1_input hwmon8/pwm3=hwmon8/fan3_input hwmon8/pwm8=hwmon8/fan8_input
      MINTEMP=hwmon8/pwm1=85 hwmon8/pwm3=55 hwmon8/pwm8=55
      MAXTEMP=hwmon8/pwm1=95 hwmon8/pwm3=75 hwmon8/pwm8=75
      MINSTART=hwmon8/pwm1=110 hwmon8/pwm3=100 hwmon8/pwm8=100
      MINSTOP=hwmon8/pwm1=90 hwmon8/pwm3=77 hwmon8/pwm8=77
      MINPWM=hwmon8/pwm1=90 hwmon8/pwm3=77 hwmon8/pwm8=77
      MAXPWM=hwmon8/pwm1=255 hwmon8/pwm3=190 hwmon8/pwm8=190
    '';
  };
}
