{
  removeByPath = pathList: set:
    lib.updateManyAttrsByPath [ 
      { 
        path = lib.init pathList;
        update = old: 
          lib.filterAttrs (n: v: n != (lib.last pathList)) old;
      }
    ] set;
}