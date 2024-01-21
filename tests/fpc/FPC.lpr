program FPC;

uses
  consoletestrunner,
  Tests.EOLib.Data;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'EOLib Tests (FPC)';
  Application.Run;
  Application.Free;
end.
