program Delphi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  TestFramework,
  TextTestRunner,
  Tests.EOLib.Data in '..\Tests.EOLib.Data.pas',
  Tests.EOLib.Encrypt in '..\Tests.EOLib.Encrypt.pas',
  Tests.EOLib.Packet in '..\Tests.EOLib.Packet.pas';

begin
  TextTestRunner.RunRegisteredTests;
end.
