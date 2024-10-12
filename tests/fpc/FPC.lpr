program FPC;

uses
  consoletestrunner,
  Tests.EOLib.Data,
  Tests.EOLib.Encrypt,
  Tests.EOLib.Packet,
  Tests.EOLib.Utils.Optional;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'EOLib Tests (FPC)';
  Application.Run;
  Application.Free;
end.
