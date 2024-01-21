unit TestFramework;

interface

uses
  fpcunit,
  testregistry;

procedure RegisterTest(Test: TTest);

type
  TTestCase = fpcunit.TTestCase;

implementation

procedure RegisterTest(Test: TTest);
begin
  testregistry.RegisterTest('', Test);
end;

end.
