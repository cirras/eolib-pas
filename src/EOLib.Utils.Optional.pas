{ Optional (nullable) type provided for usage in generated protocol data structures. }
unit EOLib.Utils.Optional;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
  {$H+}
  {$WARNINGS OFF}
  {$HINTS OFF}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  { Exception raised when an invalid operation is performed on a @link(TOptional). }
  EOptionalError = class(Exception);

  { A generic record that holds an optional (nullable) value of type @code(T).

    This type is inspired by Java's @code(Optional) type and is useful for indicating the presence or absence of a
    value, avoiding the need for sentinel values like 0 or empty string for non-nullable types. }
  TOptional<T> = record
  private
    FValue: T;
    FIsPresent: Boolean;
    function GetIsEmpty: Boolean;
  public
    { Creates an instance of @classname with a value.

      @param(Value The value to hold.)
      @returns(A @classname with a value present) }
    class function From(Value: T): TOptional<T>; static;

    { Creates an empty @classname.

      @returns(A @classname with no value present) }
    class function Empty: TOptional<T>; static;

    { Returns the held value if it is present, otherwise raises an @link(EOptionalError) if the optional is empty.

      @raises(EOptionalError If the optional is empty.)
      @returns(The held value) }
    function Get: T;

    { Tries to get the held value if it is present, returning @true if successful.

      @param(Value The out parameter that will contain the value if successful)
      @returns(@true if the value is present, @false otherwise) }
    function TryGet(out Value: T): Boolean;

    { Returns the held value if present, otherwise returns the provided default value.

      @param(Default The value to return if the optional is empty)
      @returns(The held value if present, or the provided default value) }
    function OrElse(Default: T): T;

{$IFNDEF FPC}
    { Returns the held value if present, otherwise returns the value supplied by the provided supplier function.

      @param(Supplier A function that provides the default value if the optional is empty)
      @returns(The held value if present, or the value supplied by the provided function) }
    function OrElseGet(Supplier: TFunc<T>): T;

    { Executes the provided consumer procedure if the value is present.

      @param(Consumer A procedure to execute if the value is present) }
    procedure IfPresent(Consumer: TProc<T>);
{$ENDIF}

    { Implicit conversion operator to allow assigning a value of type @code(T) directly to @classname.

      @param(Value The value to convert to TOptional.)
      @returns(A @classname holding the provided value.) }
    class operator Implicit(Value: T): TOptional<T>; inline;

    { Indicates whether the value is present. }
    property IsPresent: Boolean read FIsPresent;

    { Indicates whether the optional is empty. }
    property IsEmpty: Boolean read GetIsEmpty;
  end;

implementation

{ TOptional<T> }

function TOptional<T>.GetIsEmpty: Boolean;
begin
  Result := not FIsPresent;
end;

class function TOptional<T>.From(Value: T): TOptional<T>;
begin
  Result.FValue := Value;
  Result.FIsPresent := True;
end;

class function TOptional<T>.Empty: TOptional<T>;
begin
  Result.FValue := Default(T);
  Result.FIsPresent := False;
end;

function TOptional<T>.Get: T;
begin
  if not FIsPresent then begin
    raise EOptionalError.Create('No value present');
  end;
  Result := FValue;
end;

function TOptional<T>.TryGet(out Value: T): Boolean;
begin
  Result := FIsPresent;
  if Result then begin
    Value := FValue;
  end;
end;

function TOptional<T>.OrElse(Default: T): T;
begin
  if FIsPresent then begin
    Result := FValue;
  end
  else begin
    Result := Default;
  end;
end;

{$IFNDEF FPC}

function TOptional<T>.OrElseGet(Supplier: TFunc<T>): T;
begin
  if FIsPresent then begin
    Result := FValue;
  end
  else begin
    Result := Supplier();
  end;
end;

procedure TOptional<T>.IfPresent(Consumer: TProc<T>);
begin
  if FIsPresent then begin
    Consumer(FValue);
  end;
end;

{$ENDIF}

class operator TOptional<T>.Implicit(Value: T): TOptional<T>;
begin
  Result.FValue := Value;
  Result.FIsPresent := True;
end;

end.
