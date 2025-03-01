{ Utilities to read and write EO data types. }
unit EOLib.Data;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
  {$H+}
  {$WARNINGS OFF}
  {$HINTS OFF}
{$ENDIF}

interface

const
  { The maximum value of an EO char (1-byte encoded integer type). }
  EoCharMax = 253;

  { The maximum value of an EO short (2-byte encoded integer type). }
  EoShortMax = EoCharMax * EoCharMax;

  { The maximum value of an EO three (3-byte encoded integer type). }
  EoThreeMax = EoCharMax * EoCharMax * EoCharMax;

  { The maximum value of an EO int (4-byte encoded integer type). }
  EoIntMax = Int64(EoCharMax) * EoCharMax * EoCharMax * EoCharMax;

{ Encodes a number to a sequence of bytes.
  @param(Bytes The sequence of bytes to encode)
  @returns(The encoded sequence of bytes) }
function EncodeNumber(Number: Cardinal): TArray<Byte>;

{ Decodes a number from a sequence of bytes.
  @param(Bytes The sequence of bytes to decode)
  @returns(The decoded number) }
function DecodeNumber(Bytes: TArray<Byte>): Cardinal;

{ Encodes a string by inverting the bytes and then reversing them.

  This is an in-place operation.

  @param(Bytes The byte array to encode) }
procedure EncodeString(var Bytes: TArray<Byte>);

{ Decodes a string by reversing the bytes and then inverting them.

  This is an in-place operation.

  @param(Bytes The byte array to decode) }
procedure DecodeString(var Bytes: TArray<Byte>);

type
  { A class for reading EO data from a sequence of bytes.

    @code(TEoReader) features a chunked reading mode, which is important for
    accurate emulation of the official game client.

    See @url(https://github.com/Cirras/eo-protocol/blob/master/docs/chunks.md Chunked Reading). }
  TEoReader = class
  private
    FData: TArray<Byte>;
    FOffset: Cardinal;
    FLimit: Cardinal;
    FPosition: Cardinal;
    FChunkedReadingMode: Boolean;
    FChunkStart: Cardinal;
    FNextBreak: Cardinal;

    constructor Create(const Data: TArray<Byte>; Offset: Cardinal; Limit: Cardinal); overload;

    function ReadByte: Byte;
    function ReadBytes(Length: Cardinal): TArray<Byte>;
    function RemovePadding(const Bytes: TArray<Byte>): TArray<Byte>;
    function FindNextBreakIndex: Cardinal;

    procedure SetChunkedReadingMode(ChunkedReadingMode: Boolean);
    function GetRemaining: Cardinal;
    function GetPosition: Cardinal;

  public
    { Creates a new @code(TEoReader) instance with no data. }
    constructor Create; overload;

    { Creates a new @code(TEoReader) instance for the specified data.

      @param(Data The byte array containing the input data) }
    constructor Create(const Data: TArray<Byte>); overload;

    { Creates a new @code(TEoReader) whose input data is a shared subsequence of this reader's
      data.

      The input data of the new reader will start at this reader's current position and contain
      all remaining data. The two reader's position and chunked reading mode will be independent.

      The new reader's position will be zero, and its chunked reading mode will be @false.

      @returns(The new reader) }
    function Slice: TEoReader; overload;

    { Creates a new @code(TEoReader) whose input data is a shared subsequence of this reader's
      data.

      The input data of the new reader will start at this reader's current position and contain
      all remaining data. The two reader's position and chunked reading mode will be independent.

      The new reader's position will be zero, and its chunked reading mode will be @false.

      @param(Index The position in this reader at which the data of the new reader will start)

      @returns(The new reader) }
    function Slice(Index: Cardinal): TEoReader; overload;

    { Creates a new @code(TEoReader) whose input data is a shared subsequence of this reader's
      data.

      The input data of the new reader will start at this reader's current position and contain
      all remaining data. The two reader's position and chunked reading mode will be independent.

      The new reader's position will be zero, and its chunked reading mode will be @false.

      @param(Index The position in this reader at which the data of the new reader will start)
      @param(Length The length of the shared subsequence of data to supply to the new reader)

      @returns(The new reader) }
    function Slice(Index: Cardinal; Length: Cardinal): TEoReader; overload;

    { Reads a raw byte from the input data.

      @returns(A raw byte) }
    function GetByte: Cardinal;

    { Reads an array of raw bytes from the input data.

      @returns(An array of raw bytes) }
    function GetBytes(Length: Cardinal): TArray<Byte>;

    { Reads an encoded 1-byte integer from the input data.

      @returns(A decoded 1-byte integer) }
    function GetChar: Cardinal;

    { Reads an encoded 2-byte integer from the input data.

      @returns(A decoded 2-byte integer) }
    function GetShort: Cardinal;

    { Reads an encoded 3-byte integer from the input data.

      @returns(A decoded 3-byte integer) }
    function GetThree: Cardinal;

    { Reads an encoded 4-byte integer from the input data.

      @returns(A decoded 4-byte integer) }
    function GetInt: Cardinal;

    { Reads a string from the input data.

      @returns(A string) }
    function GetString: string;

    { Reads a string with a fixed length from the input data.

      @param(Length The length of the string)
      @param(Padded @true if the string is padded with trailing @code($FF) bytes)

      @returns(A string) }
    function GetFixedString(Length: Cardinal; Padded: Boolean = False): string; overload;

    { Reads an encoded string from the input data.

      @returns(A decoded string) }
    function GetEncodedString: string;

    { Reads an encoded string with a fixed length from the input data.

      @param(Length The length of the string)
      @param(Padded @true if the string is padded with trailing @code($FF) bytes)

      @returns(A decoded string) }
    function GetFixedEncodedString(Length: Cardinal; Padded: Boolean = False): string; overload;

    { Moves the reader position to the start of the next chunk in the input data.

      @raises(EInvalidOpException If not in chunked reading mode) }
    procedure NextChunk;

    { Whether chunked reading mode is enabled for this reader.

      In chunked reading mode:
      @unorderedList(
        @item(The reader will treat @code($FF) bytes as the end of the current chunk.)
        @item(@link(TEoReader.NextChunk) can be called to move to the next chunk.)
      ) }
    property ChunkedReadingMode: Boolean read FChunkedReadingMode write SetChunkedReadingMode;

    { If chunked reading mode is enabled, the number of bytes remaining in the current chunk. @br
      Otherwise, the total number of bytes remaining in the input data. }
    property Remaining: Cardinal read GetRemaining;

    { The current position in the input data. }
    property Position: Cardinal read GetPosition;
  end;

  { TEoWriter }

  { A class for writing EO data to a sequence of bytes. }
  TEoWriter = class
  private
    FData: TArray<Byte>;
    FLength: Cardinal;
    FStringSanitizationMode: Boolean;

    procedure InternalAddBytes(const Bytes: TArray<Byte>; BytesLength: Cardinal);
    procedure Expand(ExpandFactor: Cardinal);
    procedure SanitizeString(var Bytes: TArray<Byte>);

    class function AddPadding(const Bytes: TArray<Byte>; ExpectedLength: Cardinal): TArray<Byte>; static;
    class procedure CheckNumberSize(Number: Cardinal; Max: Cardinal); static;
    class procedure CheckStringLength(const Str: string; ExpectedLength: Cardinal; Padded: Boolean); static;

  public
    { Creates a new @code(TEoWriter) instance with no data. }
    constructor Create;

    { Adds a raw byte to the writer data.

      @param(Value The byte to be added)

      @raises(EArgumentException If the value is above @code($FF)) }
    procedure AddByte(Value: Cardinal);

    { Adds an array of raw bytes to the writer data.

      @param(Bytes The array of bytes to be added) }
    procedure AddBytes(const Bytes: TArray<Byte>);

    { Adds an encoded 1-byte integer to the writer data.

      @param(Number The number to be encoded and added)

      @raises(EArgumentException If the value is above @link(EoCharMax)) }
    procedure AddChar(Number: Cardinal);

    { Adds an encoded 2-byte integer to the writer data.

      @param(Number The number to be encoded and added)

      @raises(EArgumentException If the value is above @link(EoShortMax)) }
    procedure AddShort(Number: Cardinal);

    { Adds an encoded 3-byte integer to the writer data.

      @param(Number The number to be encoded and added)

      @raises(EArgumentException If the value is above @link(EoThreeMax)) }
    procedure AddThree(Number: Cardinal);

    { Adds an encoded 4-byte integer to the writer data.

      @param(Number The number to be encoded and added)

      @raises(EArgumentException If the value is above @link(EoIntMax)) }
    procedure AddInt(Number: Cardinal);

    { Adds a string to the writer data.

      @param(Str The string to be added) }
    procedure AddString(Str: string);

    { Adds a fixed-length string to the writer data.

      @param(Str The string to be added)
      @param(Length The expected length of the string)
      @param(Padded @true if @code(Str) should be padded to @code(Length) with trailing @code($FF) bytes)

      @raises(EArgumentException If the string does not have the expected length) }
    procedure AddFixedString(Str: string; ExpectedLength: Cardinal; Padded: Boolean = False); overload;

    { Adds an encoded string to the writer data.

      @param(Str The string to be encoded and added) }
    procedure AddEncodedString(Str: string);

    { Adds a fixed-length encoded string to the writer data.

      @param(Str The string to be encoded and added)
      @param(Length The expected length of the string)
      @param(Padded @true if @code(Str) should be padded to @code(Length) with trailing @code($FF) bytes)

      @raises(EArgumentException If the string does not have the expected length) }
    procedure AddFixedEncodedString(Str: string; ExpectedLength: Cardinal; Padded: Boolean = False); overload;

    { Gets the writer data as a byte array.

      @returns(A copy of the writer data as a byte array) }
    function ToByteArray: TArray<Byte>;

    { If string sanitization mode is enabled, the writer will switch @code($FF) (ÿ) bytes in
      strings to @code($79) (y).

      See:

      @url(https://github.com/Cirras/eo-protocol/blob/master/docs/chunks.md#sanitization Chunked Reading: Sanitization) }
    property StringSanitizationMode: Boolean read FStringSanitizationMode write FStringSanitizationMode;

    { The length of the writer data. }
    property Length: Cardinal read FLength;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils,
  Math;
{$ELSE}
  System.SysUtils,
  System.Math;
{$ENDIF}

var
  Windows1252: TEncoding;

function EncodeNumber(Number: Cardinal): TArray<Byte>;
var
  Value: Cardinal;
  A: Byte;
  B: Byte;
  C: Byte;
  D: Byte;
begin
  Value := Number;
  D := $FE;
  if Number >= EoThreeMax then begin
    D := Value div EoThreeMax + 1;
    Value := Value mod EoThreeMax;
  end;

  C := $FE;
  if Number >= EoShortMax then begin
    C := Value div EoShortMax + 1;
    Value := Value mod EoShortMax;
  end;

  B := $FE;
  if Number >= EoCharMax then begin
    B := Value div EoCharMax + 1;
    Value := Value mod EoCharMax;
  end;

  A := Value + 1;

  Result := TArray<Byte>.Create(A, B, C, D);
end;

function DecodeNumber(Bytes: TArray<Byte>): Cardinal;
var
  BytesLength: Integer;
  I: Integer;
  Value: Byte;
begin
  Result := 0;
  BytesLength := Min(Length(Bytes), 4);

  for I := 0 to BytesLength - 1 do begin
    Value := Bytes[I];

    if Value = $FE then begin
      Break;
    end;

    Dec(Value);

    case I of
      0:
        Result := Result + Value;
      1:
        Result := Result + EoCharMax * Value;
      2:
        Result := Result + EoShortMax * Value;
      3:
        Result := Result + EoThreeMax * Value;
    end;
  end;
end;

procedure InvertCharacters(var Bytes: TArray<Byte>);
var
  Flippy: Boolean;
  I: Integer;
  C: Byte;
  F: Integer;
begin
  Flippy := (Length(Bytes) mod 2) = 1;

  for I := 0 to High(Bytes) do begin
    C := Bytes[I];
    F := 0;

    if Flippy then begin
      F := $2E;
      if C >= $50 then begin
        F := F * -1;
      end;
    end;

    if (C >= $22) and (C <= $7E) then begin
      Bytes[I] := $9F - C - F;
    end;

    Flippy := not Flippy;
  end;
end;

procedure ReverseCharacters(var Bytes: TArray<Byte>);
var
  I: Integer;
  B: Byte;
begin
  for I := 0 to High(Bytes) div 2 do begin
    B := Bytes[I];
    Bytes[I] := Bytes[High(Bytes) - I];
    Bytes[High(Bytes) - I] := B;
  end;
end;

procedure EncodeString(var Bytes: TArray<Byte>);
begin
  InvertCharacters(Bytes);
  ReverseCharacters(Bytes);
end;

procedure DecodeString(var Bytes: TArray<Byte>);
begin
  ReverseCharacters(Bytes);
  InvertCharacters(Bytes);
end;

{ TEoReader }

constructor TEoReader.Create;
begin
  Create([]);
end;

constructor TEoReader.Create(const Data: TArray<Byte>);
begin
  Create(Data, 0, Length(Data));
end;

constructor TEoReader.Create(const Data: TArray<Byte>; Offset, Limit: Cardinal);
begin
  FData := Data;
  FOffset := Offset;
  FLimit := Limit;
  FPosition := 0;
  FChunkedReadingMode := False;
  FChunkStart := 0;
  FNextBreak := High(Cardinal);
end;

function TEoReader.Slice: TEoReader;
begin
  Result := Slice(FPosition);
end;

function TEoReader.Slice(Index: Cardinal): TEoReader;
var
  Length: Cardinal;
begin
  if Index < FLimit then begin
    Length := FLimit - Index;
  end
  else begin
    Length := 0;
  end;
  Result := Slice(Index, Length);
end;

function TEoReader.Slice(Index: Cardinal; Length: Cardinal): TEoReader;
var
  SliceOffset: Cardinal;
  SliceLimit: Cardinal;
begin
  SliceOffset := Min(FLimit, Index);
  SliceLimit := Min(FLimit - SliceOffset, Length);

  Result := TEoReader.Create(FData, SliceOffset, SliceLimit);
end;

function TEoReader.GetByte: Cardinal;
begin
  Result := ReadByte;
end;

function TEoReader.GetBytes(Length: Cardinal): TArray<Byte>;
begin
  Result := ReadBytes(Length);
end;

function TEoReader.GetChar: Cardinal;
begin
  Result := DecodeNumber(ReadBytes(1));
end;

function TEoReader.GetShort: Cardinal;
begin
  Result := DecodeNumber(ReadBytes(2));
end;

function TEoReader.GetThree: Cardinal;
begin
  Result := DecodeNumber(ReadBytes(3));
end;

function TEoReader.GetInt: Cardinal;
begin
  Result := DecodeNumber(ReadBytes(4));
end;

function TEoReader.GetString: string;
var
  Bytes: TArray<Byte>;
begin
  Bytes := ReadBytes(GetRemaining);
  Result := Windows1252.GetString(Bytes);
end;

function TEoReader.GetFixedString(Length: Cardinal; Padded: Boolean): string;
var
  Bytes: TArray<Byte>;
begin
  Bytes := ReadBytes(Length);
  if Padded then begin
    Bytes := RemovePadding(Bytes);
  end;

  Result := Windows1252.GetString(Bytes);
end;

function TEoReader.GetEncodedString: string;
var
  Bytes: TArray<Byte>;
begin
  Bytes := ReadBytes(GetRemaining);
  DecodeString(Bytes);
  Result := Windows1252.GetString(Bytes);
end;

function TEoReader.GetFixedEncodedString(Length: Cardinal; Padded: Boolean): string;
var
  Bytes: TArray<Byte>;
begin
  Bytes := ReadBytes(Length);
  DecodeString(Bytes);
  if Padded then begin
    Bytes := RemovePadding(Bytes);
  end;

  Result := Windows1252.GetString(Bytes);
end;

procedure TEoReader.SetChunkedReadingMode(ChunkedReadingMode: Boolean);
begin
  FChunkedReadingMode := ChunkedReadingMode;
  if FNextBreak = High(Cardinal) then begin
    FNextBreak := FindNextBreakIndex;
  end;
end;

function TEoReader.GetRemaining: Cardinal;
begin
  if FChunkedReadingMode then begin
    Result := FNextBreak - Min(FPosition, FNextBreak);
  end
  else begin
    Result := FLimit - FPosition;
  end;
end;

procedure TEoReader.NextChunk;
begin
  if not FChunkedReadingMode then begin
    raise EInvalidOpException.Create('Not in chunked reading mode.');
  end;

  FPosition := FNextBreak;
  if FPosition < FLimit then begin
    Inc(FPosition);
  end;

  FChunkStart := FPosition;
  FNextBreak := FindNextBreakIndex;
end;

function TEoReader.GetPosition: Cardinal;
begin
  Result := FPosition;
end;

function TEoReader.ReadByte: Byte;
begin
  if GetRemaining > 0 then begin
    Result := FData[FOffset + FPosition];
  end
  else begin
    Result := 0;
  end;
  Inc(FPosition);
end;

function TEoReader.ReadBytes(Length: Cardinal): TArray<Byte>;
begin
  Length := Min(Length, GetRemaining);

  SetLength(Result {%H-}, Length);

  if Length <> 0 then begin
    Move(FData[FOffset + FPosition], Result[0], Length);
    Inc(FPosition, Length);
  end;
end;

function TEoReader.RemovePadding(const Bytes: TArray<Byte>): TArray<Byte>;
var
  I: Integer;
begin
  for I := 0 to High(Bytes) do begin
    if Bytes[I] = $FF then begin
      SetLength(Result {%H-}, I);
      Move(Bytes[0], Result[0], I);
      Exit;
    end;
  end;
  Result := Bytes;
end;

function TEoReader.FindNextBreakIndex: Cardinal;
var
  I: Cardinal;
begin
  I := FChunkStart;
  while I < FLimit do begin
    if FData[FOffset + I] = $FF then begin
      Break;
    end;
    Inc(I);
  end;
  Result := I;
end;

{ TEoWriter }

constructor TEoWriter.Create;
begin
  SetLength(FData, 16);
end;

procedure TEoWriter.AddByte(Value: Cardinal);
begin
  CheckNumberSize(Value, $FF);
  if FLength + 1 > Cardinal(System.Length(FData)) then begin
    Expand(2);
  end;
  FData[FLength] := Byte(Value);
  Inc(FLength);
end;

procedure TEoWriter.AddBytes(const Bytes: TArray<Byte>);
begin
  InternalAddBytes(Bytes, System.Length(Bytes));
end;

procedure TEoWriter.AddChar(Number: Cardinal);
var
  Bytes: TArray<Byte>;
begin
  CheckNumberSize(Number, EoCharMax - 1);
  Bytes := EncodeNumber(Number);
  InternalAddBytes(Bytes, 1);
end;

procedure TEoWriter.AddShort(Number: Cardinal);
var
  Bytes: TArray<Byte>;
begin
  CheckNumberSize(Number, EoShortMax - 1);
  Bytes := EncodeNumber(Number);
  InternalAddBytes(Bytes, 2);
end;

procedure TEoWriter.AddThree(Number: Cardinal);
var
  Bytes: TArray<Byte>;
begin
  CheckNumberSize(Number, EoThreeMax - 1);
  Bytes := EncodeNumber(Number);
  InternalAddBytes(Bytes, 3);
end;

procedure TEoWriter.AddInt(Number: Cardinal);
var
  Bytes: TArray<Byte>;
begin
  CheckNumberSize(Number, EoIntMax - 1);
  Bytes := EncodeNumber(Number);
  InternalAddBytes(Bytes, 4);
end;

procedure TEoWriter.AddString(Str: string);
var
  Bytes: TArray<Byte>;
begin
  Bytes := Windows1252.GetBytes(Str);
  SanitizeString(Bytes);
  AddBytes(Bytes);
end;

procedure TEoWriter.AddFixedString(Str: string; ExpectedLength: Cardinal; Padded: Boolean);
var
  Bytes: TArray<Byte>;
begin
  CheckStringLength(Str, ExpectedLength, Padded);
  Bytes := Windows1252.GetBytes(Str);
  SanitizeString(Bytes);
  if Padded then begin
    Bytes := AddPadding(Bytes, ExpectedLength);
  end;
  AddBytes(Bytes);
end;

procedure TEoWriter.AddEncodedString(Str: string);
var
  Bytes: TArray<Byte>;
begin
  Bytes := Windows1252.GetBytes(Str);
  SanitizeString(Bytes);
  EncodeString(Bytes);
  AddBytes(Bytes);
end;

procedure TEoWriter.AddFixedEncodedString(Str: string; ExpectedLength: Cardinal; Padded: Boolean);
var
  Bytes: TArray<Byte>;
begin
  CheckStringLength(Str, ExpectedLength, Padded);
  Bytes := Windows1252.GetBytes(Str);
  SanitizeString(Bytes);
  if Padded then begin
    Bytes := AddPadding(Bytes, ExpectedLength);
  end;
  EncodeString(Bytes);
  AddBytes(Bytes);
end;

function TEoWriter.ToByteArray: TArray<Byte>;
begin
  SetLength(Result {%H-}, FLength);
  Move(FData[0], Result[0], FLength);
end;

procedure TEoWriter.InternalAddBytes(const Bytes: TArray<Byte>; BytesLength: Cardinal);
var
  ExpandFactor: Cardinal;
begin
  ExpandFactor := 1;
  while FLength + BytesLength > Cardinal(System.Length(FData)) * ExpandFactor do begin
    ExpandFactor := ExpandFactor * 2;
  end;

  if ExpandFactor > 1 then begin
    Expand(ExpandFactor);
  end;

  Move(Bytes[0], FData[FLength], BytesLength);
  Inc(FLength, BytesLength);
end;

procedure TEoWriter.Expand(ExpandFactor: Cardinal);
var
  Expanded: TArray<Byte>;
begin
  SetLength(Expanded {%H-}, Cardinal(System.Length(FData)) * ExpandFactor);
  Move(FData[0], Expanded[0], FLength);
  FData := Expanded;
end;

procedure TEoWriter.SanitizeString(var Bytes: TArray<Byte>);
var
  I: Integer;
begin
  if FStringSanitizationMode then begin
    for I := 0 to System.Length(Bytes) - 1 do begin
      if Bytes[I] = $FF {ÿ} then begin
        Bytes[I] := $79 {y};
      end;
    end;
  end;
end;

class function TEoWriter.AddPadding(const Bytes: TArray<Byte>; ExpectedLength: Cardinal): TArray<Byte>;
var
  I: Integer;
begin
  if Cardinal(System.Length(Bytes)) = ExpectedLength then begin
    Result := Bytes;
  end
  else begin
    SetLength(Result, ExpectedLength);
    Move(Bytes[0], Result[0], System.Length(Bytes));
    for I := System.Length(Bytes) to ExpectedLength - 1 do begin
      Result[I] := $FF;
    end;
  end;
end;

class procedure TEoWriter.CheckNumberSize(Number: Cardinal; Max: Cardinal);
begin
  if Number > Max then begin
    raise EArgumentException.CreateFmt('Value %d exceeds maximum of %d.', [Number, Max]);
  end;
end;

class procedure TEoWriter.CheckStringLength(const Str: string; ExpectedLength: Cardinal; Padded: Boolean);
begin
  if Padded then begin
    if ExpectedLength >= Cardinal(System.Length(Str)) then begin
      Exit;
    end;
    raise EArgumentException.CreateFmt('Padded string "%s" is too large for a length of %d.', [Str, ExpectedLength]);
  end;

  if Cardinal(System.Length(Str)) <> ExpectedLength then begin
    raise EArgumentException.CreateFmt('String "%s" does not have expected length of %d.', [Str, ExpectedLength]);
  end;
end;

initialization
  Windows1252 := TEncoding.GetEncoding(1252);

finalization
  FreeAndNil(Windows1252);

end.
