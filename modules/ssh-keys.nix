let
  keyFilesList = [
    "main.pub"
    "backup.pub"
  ];
  
  secretsDir = ../pubkeys; 
in
map (fileName: 
  builtins.replaceStrings ["\n"] [""] (builtins.readFile "${secretsDir}/${fileName}")
) keyFilesList