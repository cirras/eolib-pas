unit Tests.EOLib.Utils.Optional;

interface

uses
  TestFramework;

type
  TTestOptional = class(TTestCase)
  published
    procedure TestFrom;
    procedure TestEmpty;
    procedure TestGet;
    procedure TestTryGet;
    procedure TestOrElse;
{$IFNDEF FPC}
    procedure TestOrElseGet;
    procedure TestIfPresent;
{$ENDIF}
    procedure TestImplicitConversion;
  end;

implementation

uses
  SysUtils,
  EOLib.Utils.Optional;

{ TTestOptional }

procedure TTestOptional.TestFrom;
var
  Optional: TOptional<Integer>;
begin
  Optional := TOptional<Integer>.From(10);
  CheckTrue(Optional.IsPresent, 'Expected value to be present.');
  CheckEquals(10, Optional.Get, 'Expected value to be 10.');
end;

procedure TTestOptional.TestEmpty;
var
  Optional: TOptional<Integer>;
begin
  Optional := TOptional<Integer>.Empty;
  CheckFalse(Optional.IsPresent, 'Expected no value to be present.');
  CheckTrue(Optional.IsEmpty, 'Expected the optional to be empty.');
end;

procedure TTestOptional.TestGet;
var
  Optional: TOptional<Integer>;
begin
  Optional := TOptional<Integer>.From(20);
  CheckEquals(20, Optional.Get, 'Expected value to be 20.');

  Optional := TOptional<Integer>.Empty;
  try
    Optional.Get;
    Fail('Expected an EOptionalError to be raised.');
  except
    on E: Exception do begin
      CheckIs(E, EOptionalError, 'Expected EOptionalError to be raised.');
    end;
  end;
end;

procedure TTestOptional.TestTryGet;
var
  Optional: TOptional<Integer>;
  Value: Integer;
begin
  Optional := TOptional<Integer>.From(30);
  CheckTrue(Optional.TryGet(Value), 'Expected TryGet to return True.');
  CheckEquals(30, Value, 'Expected value to be 30.');

  Optional := TOptional<Integer>.Empty;
  CheckFalse(Optional.TryGet(Value), 'Expected TryGet to return False.');
end;

procedure TTestOptional.TestOrElse;
var
  Optional: TOptional<Integer>;
begin
  Optional := TOptional<Integer>.From(40);
  CheckEquals(40, Optional.OrElse(50), 'Expected value to be 40.');

  Optional := TOptional<Integer>.Empty;
  CheckEquals(50, Optional.OrElse(50), 'Expected value to be the default 50.');
end;

{$IFNDEF FPC}

procedure TTestOptional.TestOrElseGet;
var
  Optional: TOptional<Integer>;
begin
  Optional := TOptional<Integer>.From(60);
  CheckEquals(
      60,
      Optional.OrElseGet(
          function: Integer //
          begin
            Result := 70;
          end
      ),
      'Expected value to be 60.'
  );

  Optional := TOptional<Integer>.Empty;
  CheckEquals(
      70,
      Optional.OrElseGet(
          function: Integer //
          begin
            Result := 70;
          end
      ),
      'Expected value to be 70.'
  );
end;

procedure TTestOptional.TestIfPresent;
var
  Optional: TOptional<Integer>;
  Called: Boolean;
begin
  Called := False;
  Optional := TOptional<Integer>.From(80);
  Optional.IfPresent(
      procedure(Value: Integer)
      begin
        Called := True;
        CheckEquals(80, Value, 'Expected value to be 80.');
      end
  );
  CheckTrue(Called, 'Expected consumer to be called.');

  Called := False;
  Optional := TOptional<Integer>.Empty;
  Optional.IfPresent(
      procedure(Value: Integer) //
      begin
        Called := True;
      end
  );
  CheckFalse(Called, 'Expected consumer not to be called for empty optional.');
end;

{$ENDIF}

procedure TTestOptional.TestImplicitConversion;
var
  Optional: TOptional<Integer>;
begin
  Optional := 90;
  CheckTrue(Optional.IsPresent, 'Expected value to be present after implicit conversion.');
  CheckEquals(90, Optional.Get, 'Expected value to be 90.');
end;

initialization
  RegisterTest(TTestOptional.Suite);

end.
