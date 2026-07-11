{ pkgs, lib }:
{
  writeAwkApplication =
    name:
    {
      text,
      awkPackage ? pkgs.gawk,
    }:
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = ''
        #!${lib.getExe awkPackage} -f
        ${text}
      '';
      checkPhase = /* bash */ ''
        runHook preCheck 
        ${lib.getExe awkPackage} --lint -f $target /dev/null
        runHook postCheck
      '';
    };
  toAwk =
    contents:
    lib.concatLines (
      lib.mapAttrsToList (rule: action: ''
        ${rule} {
          ${action}
        }
      '') contents
    );
}
