{ hostname, ... }:
{
  imports = [
    ./${hostname}
  ];
}
