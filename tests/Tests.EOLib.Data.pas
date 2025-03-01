unit Tests.EOLib.Data;

interface

uses
  TestFramework;

type
  TTestEncodingUtilities = class(TTestCase)
    procedure TestEncodeNumber;
    procedure TestDecodeNumber;
    procedure TestEncodeString;
    procedure TestDecodeString;
  end;

  TTestEoReader = class(TTestCase)
    procedure TestCreateEmpty;
    procedure TestSlice;
    procedure TestSliceOverRead;
    procedure TestGetByte;
    procedure TestOverReadByte;
    procedure TestGetBytes;
    procedure TestGetChar;
    procedure TestGetShort;
    procedure TestGetThree;
    procedure TestGetInt;
    procedure TestGetString;
    procedure TestGetFixedString;
    procedure TestPaddedGetFixedString;
    procedure TestChunkedGetString;
    procedure TestGetEncodedString;
    procedure TestFixedGetEncodedString;
    procedure TestPaddedGetFixedEncodedString;
    procedure TestChunkedGetEncodedString;
    procedure TestGetRemaining;
    procedure TestChunkedGetRemaining;
    procedure TestNextChunk;
    procedure TestNextChunkNotInChunkedReadingMode;
    procedure TestNextChunkWithChunkedReadingToggledInBetween;
    procedure TestUnderRead;
    procedure TestOverRead;
    procedure TestDoubleRead;
  end;

  TTestEoWriter = class(TTestCase)
    procedure TestAddByte;
    procedure TestAddBytes;
    procedure TestAddChar;
    procedure TestAddShort;
    procedure TestAddThree;
    procedure TestAddInt;
    procedure TestAddString;
    procedure TestAddFixedString;
    procedure TestAddPaddedFixedString;
    procedure TestAddPaddedWithPerfectFitFixedString;
    procedure TestAddEncodedString;
    procedure TestAddFixedEncodedString;
    procedure TestAddPaddedFixedEncodedString;
    procedure TestAddPaddedWithPerfectFitFixedEncodedString;
    procedure TestAddSanitizedString;
    procedure TestAddSanitizedFixedString;
    procedure TestAddSanitizedPaddedFixedString;
    procedure TestAddSanitizedEncodedString;
    procedure TestAddSanitizedFixedEncodedString;
    procedure TestAddSanitizedPaddedFixedEncodedString;
    procedure TestAddNumbersOnBoundary;
    procedure TestAddNumbersExceedingLimit;
    procedure TestAddFixedStringWithIncorrectLength;
    procedure TestLength;
  end;

implementation

uses
  SysUtils,
  EOLib.Data;

type
  TNumberData = record
    Decoded: Cardinal;
    Encoded: TArray<Byte>;
    function EncodedToString: string;
  end;

  TStringData = record
    Decoded: string;
    Encoded: string;
  end;

const
  Numbers: array[0..23] of TNumberData = (
      (Decoded: 0; Encoded: [$01, $FE, $FE, $FE]),
      (Decoded: 1; Encoded: [$02, $FE, $FE, $FE]),
      (Decoded: 28; Encoded: [$1D, $FE, $FE, $FE]),
      (Decoded: 100; Encoded: [$65, $FE, $FE, $FE]),
      (Decoded: 128; Encoded: [$81, $FE, $FE, $FE]),
      (Decoded: 252; Encoded: [$FD, $FE, $FE, $FE]),
      (Decoded: 253; Encoded: [$01, $02, $FE, $FE]),
      (Decoded: 254; Encoded: [$02, $02, $FE, $FE]),
      (Decoded: 255; Encoded: [$03, $02, $FE, $FE]),
      (Decoded: 32003; Encoded: [$7E, $7F, $FE, $FE]),
      (Decoded: 32004; Encoded: [$7F, $7F, $FE, $FE]),
      (Decoded: 32005; Encoded: [$80, $7F, $FE, $FE]),
      (Decoded: 64008; Encoded: [$FD, $FD, $FE, $FE]),
      (Decoded: 64009; Encoded: [$01, $01, $02, $FE]),
      (Decoded: 64010; Encoded: [$02, $01, $02, $FE]),
      (Decoded: 10000000; Encoded: [$B0, $3A, $9D, $FE]),
      (Decoded: 16194276; Encoded: [$FD, $FD, $FD, $FE]),
      (Decoded: 16194277; Encoded: [$01, $01, $01, $02]),
      (Decoded: 16194278; Encoded: [$02, $01, $01, $02]),
      (Decoded: 2048576039; Encoded: [$7E, $7F, $7F, $7F]),
      (Decoded: 2048576040; Encoded: [$7F, $7F, $7F, $7F]),
      (Decoded: 2048576041; Encoded: [$80, $7F, $7F, $7F]),
      (Decoded: 4097152079; Encoded: [$FC, $FD, $FD, $FD]),
      (Decoded: 4097152080; Encoded: [$FD, $FD, $FD, $FD])
  );

  Strings: array[0..5] of TStringData = (
      (Decoded: 'Hello, World!'; Encoded: '!;a-^H s^3a:)'),
      (
          Decoded: 'We''re ¼ of the way there, so ¾ is remaining.';
          Encoded: 'C8_6_6l2h- ,d ¾ ^, sh-h7Y T>V h7Y g0 ¼ :[xhH'
      ),
      (Decoded: '64² = 4096'; Encoded: ';fAk b ²=i'),
      (Decoded: '© FÒÖ BÃR BÅZ 2014'; Encoded: '=nAm EÅ] MÃ] ÖÒY ©'),
      (Decoded: 'Öxxö Xööx "Lëïth Säë" - "Ÿ"'; Encoded: 'OŸO D OëäL 7YïëSO UööG öU''Ö'),
      (Decoded: 'Padded with 0xFFÿÿÿÿÿÿÿÿ'; Encoded: 'ÿÿÿÿÿÿÿÿ+YUo 7Y6V i:i;lO')
  );

function ToBytes(Str: string): TArray<Byte>;
var
  Encoding: TEncoding;
begin
  Encoding := TEncoding.GetEncoding(1252);
  Result := Encoding.GetBytes(Str);
  FreeAndNil(Encoding);
end;

function FromBytes(const Bytes: TArray<Byte>): string;
var
  Encoding: TEncoding;
begin
  Encoding := TEncoding.GetEncoding(1252);
  Result := Encoding.GetString(Bytes);
  FreeAndNil(Encoding);
end;

function CreateReader(const Bytes: TArray<Byte>): TEoReader; overload;
var
  Data: TArray<Byte>;
  I: Integer;
  Reader: TEoReader;
begin
  SetLength(Data {%H-}, Length(Bytes) + 20);
  for I := 0 to High(Bytes) do begin
    Data[10 + I] := Bytes[I];
  end;
  Reader := TEoReader.Create(Data);
  Result := Reader.Slice(10, Length(Bytes));
  FreeAndNil(Reader);
end;

function CreateReader(const Str: string): TEoReader; overload;
begin
  Result := TEoReader.Create(ToBytes(Str));
end;

{ TNumberData }

function TNumberData.EncodedToString: string;
begin
  Result := {%H-} Format('[%x, %x, %x, %x]', [Encoded[0], Encoded[1], Encoded[2], Encoded[3]]);
end;

{ TTestEncodingUtilities }

procedure TTestEncodingUtilities.TestEncodeNumber;
var
  Number: TNumberData;
begin
  for Number in Numbers do begin
    Check(
        CompareMem(@EncodeNumber(Number.Decoded)[0], @Number.Encoded[0], 4),
        Format('%d should encode to %s', [Number.Decoded, Number.EncodedToString])
    );
  end;
end;

procedure TTestEncodingUtilities.TestDecodeNumber;
var
  Number: TNumberData;
begin
  for Number in Numbers do begin
    CheckEquals(
        Number.Decoded,
        DecodeNumber(Number.Encoded),
        Format('%s should decode to %d', [Number.EncodedToString, Number.Decoded])
    );
  end;
end;

procedure TTestEncodingUtilities.TestEncodeString;
var
  Str: TStringData;
  Bytes: TArray<Byte>;
begin
  for Str in Strings do begin
    Bytes := ToBytes(Str.Decoded);

    EncodeString(Bytes);

    CheckEquals(Str.Encoded, FromBytes(Bytes), Format('''%s'' should encode to ''%s''', [Str.Decoded, Str.Encoded]));
  end;
end;

procedure TTestEncodingUtilities.TestDecodeString;
var
  Str: TStringData;
  Bytes: TArray<Byte>;
begin
  for Str in Strings do begin
    Bytes := ToBytes(Str.Encoded);

    DecodeString(Bytes);

    CheckEquals(Str.Decoded, FromBytes(Bytes), Format('''%s'' should decode to ''%s''', [Str.Encoded, Str.Decoded]));
  end;
end;

{ TEoReaderTest }

procedure TTestEoReader.TestCreateEmpty;
var
  Reader: TEoReader;
begin
  Reader := TEoReader.Create;
  CheckEquals(0, Reader.Remaining);
  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestSlice;
var
  Reader: TEoReader;
  Reader2: TEoReader;
  Reader3: TEoReader;
  Reader4: TEoReader;
begin
  Reader := CreateReader([$01, $02, $03, $04, $05, $06]);

  Reader.GetByte;
  Reader.ChunkedReadingMode := True;

  Reader2 := Reader.Slice;
  Reader3 := Reader2.Slice(1);
  Reader4 := Reader3.Slice(1, 2);

  CheckEquals(0, Reader2.Position);
  CheckEquals(5, Reader2.Remaining);
  CheckFalse(Reader2.ChunkedReadingMode);

  CheckEquals(0, Reader3.Position);
  CheckEquals(4, Reader3.Remaining);
  CheckFalse(Reader3.ChunkedReadingMode);

  CheckEquals(0, Reader4.Position);
  CheckEquals(2, Reader4.Remaining);
  CheckFalse(Reader4.ChunkedReadingMode);

  CheckEquals(1, Reader.Position);
  CheckEquals(5, Reader.Remaining);
  CheckTrue(Reader.ChunkedReadingMode);

  FreeAndNil(Reader);
  FreeAndNil(Reader2);
  FreeAndNil(Reader3);
  FreeAndNil(Reader4);
end;

procedure TTestEoReader.TestSliceOverRead;
var
  Reader: TEoReader;
  Slice: TEoReader;
  Slice2: TEoReader;
  Slice3: TEoReader;
  Slice4: TEoReader;
begin
  Reader := CreateReader([$01, $02, $03]);
  Slice := Reader.Slice(2, 5);
  Slice2 := Reader.Slice(3);
  Slice3 := Reader.Slice(4);
  Slice4 := Reader.Slice(4, 12345);

  CheckEquals(1, Slice.Remaining);
  CheckEquals(0, Slice2.Remaining);
  CheckEquals(0, Slice3.Remaining);
  CheckEquals(0, Slice4.Remaining);

  FreeAndNil(Reader);
  FreeAndNil(Slice);
  FreeAndNil(Slice2);
  FreeAndNil(Slice3);
  FreeAndNil(Slice4);
end;

procedure TTestEoReader.TestGetByte;
var
  Reader: TEoReader;
  ByteValue: Integer;
begin
  for ByteValue in [$00, $01, $02, $80, $FD, $FE, $FF] do begin
    Reader := CreateReader([ByteValue]);

    CheckEquals(ByteValue, Reader.GetByte);

    FreeAndNil(Reader);
  end;
end;

procedure TTestEoReader.TestOverReadByte;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([]);

  CheckEquals($00, Reader.GetByte);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetBytes;
var
  Reader: TEoReader;
  Bytes: TArray<Byte>;
begin
  Reader := CreateReader([$01, $02, $03, $04, $05]);

  Bytes := Reader.GetBytes(3);
  CheckEquals(3, Length(Bytes));
  CheckEquals($01, Bytes[0]);
  CheckEquals($02, Bytes[1]);
  CheckEquals($03, Bytes[2]);

  Bytes := Reader.GetBytes(10);
  CheckEquals(2, Length(Bytes));
  CheckEquals($04, Bytes[0]);
  CheckEquals($05, Bytes[1]);

  Bytes := Reader.GetBytes(1);
  CheckEquals(0, Length(Bytes));

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetChar;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $02, $80, $81, $FD, $FE, $FF]);

  CheckEquals(0, Reader.GetChar);
  CheckEquals(1, Reader.GetChar);
  CheckEquals(127, Reader.GetChar);
  CheckEquals(128, Reader.GetChar);
  CheckEquals(252, Reader.GetChar);
  CheckEquals(0, Reader.GetChar);
  CheckEquals(254, Reader.GetChar);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetShort;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $FE, $02, $FE, $80, $FE, $FD, $FE, $FE, $FE, $FE, $80, $7F, $7F, $FD, $FD]);

  CheckEquals(0, Reader.GetShort);
  CheckEquals(1, Reader.GetShort);
  CheckEquals(127, Reader.GetShort);
  CheckEquals(252, Reader.GetShort);
  CheckEquals(0, Reader.GetShort);
  CheckEquals(0, Reader.GetShort);
  CheckEquals(32004, Reader.GetShort);
  CheckEquals(64008, Reader.GetShort);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetThree;
var
  Reader: TEoReader;
begin
  Reader :=
      CreateReader(
          [
              $01,
              $FE,
              $FE,
              $02,
              $FE,
              $FE,
              $80,
              $FE,
              $FE,
              $FD,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $80,
              $81,
              $7F,
              $7F,
              $FE,
              $FD,
              $FD,
              $FE,
              $FD,
              $FD,
              $FD
          ]
      );

  CheckEquals(0, Reader.GetThree);
  CheckEquals(1, Reader.GetThree);
  CheckEquals(127, Reader.GetThree);
  CheckEquals(252, Reader.GetThree);
  CheckEquals(0, Reader.GetThree);
  CheckEquals(0, Reader.GetThree);
  CheckEquals(32004, Reader.GetThree);
  CheckEquals(64008, Reader.GetThree);
  CheckEquals(16194276, Reader.GetThree);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetInt;
var
  Reader: TEoReader;
begin
  Reader :=
      CreateReader(
          [
              $01,
              $FE,
              $FE,
              $FE,
              $02,
              $FE,
              $FE,
              $FE,
              $80,
              $FE,
              $FE,
              $FE,
              $FD,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $FE,
              $80,
              $81,
              $82,
              $7F,
              $7F,
              $FE,
              $FE,
              $FD,
              $FD,
              $FE,
              $FE,
              $FD,
              $FD,
              $FD,
              $FE,
              $7F,
              $7F,
              $7F,
              $7F,
              $FD,
              $FD,
              $FD,
              $FD
          ]
      );

  CheckEquals(0, Reader.GetInt);
  CheckEquals(1, Reader.GetInt);
  CheckEquals(127, Reader.GetInt);
  CheckEquals(252, Reader.GetInt);
  CheckEquals(0, Reader.GetInt);
  CheckEquals(0, Reader.GetInt);
  CheckEquals(32004, Reader.GetInt);
  CheckEquals(64008, Reader.GetInt);
  CheckEquals(16194276, Reader.GetInt);
  CheckEquals(2048576040, Reader.GetInt);
  CheckEquals(4097152080, Reader.GetInt);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('Hello, World!');

  CheckEquals('Hello, World!', Reader.GetString);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetFixedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('foobar');

  CheckEquals('foo', Reader.GetFixedString(3));
  CheckEquals('bar', Reader.GetFixedString(3));

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestPaddedGetFixedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('fooÿbarÿÿÿ');

  CheckEquals('foo', Reader.GetFixedString(4, True));
  CheckEquals('bar', Reader.GetFixedString(6, True));

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestChunkedGetString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('Hello,ÿWorld!');
  Reader.ChunkedReadingMode := True;

  CheckEquals('Hello,', Reader.GetString);

  Reader.NextChunk;
  CheckEquals('World!', Reader.GetString);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetEncodedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('!;a-^H s^3a:)');

  CheckEquals('Hello, World!', Reader.GetEncodedString);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestFixedGetEncodedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('^0g[>k');

  CheckEquals('foo', Reader.GetFixedEncodedString(3));
  CheckEquals('bar', Reader.GetFixedEncodedString(3));

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestPaddedGetFixedEncodedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('ÿ0^9ÿÿÿ-l=S>k');

  CheckEquals('foo', Reader.GetFixedEncodedString(4, True));
  CheckEquals('bar', Reader.GetFixedEncodedString(6, True));
  CheckEquals('baz', Reader.GetFixedEncodedString(3, True));

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestChunkedGetEncodedString;
var
  Reader: TEoReader;
begin
  Reader := CreateReader('E0a3hWÿ!;a-^H');
  Reader.ChunkedReadingMode := True;

  CheckEquals('Hello,', Reader.GetEncodedString);

  Reader.NextChunk;
  CheckEquals('World!', Reader.GetEncodedString);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestGetRemaining;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $03, $04, $FE, $05, $FE, $FE, $06, $FE, $FE, $FE]);

  CheckEquals(11, Reader.Remaining);
  Reader.GetByte;
  CheckEquals(10, Reader.Remaining);
  Reader.GetChar;
  CheckEquals(9, Reader.Remaining);
  Reader.GetShort;
  CheckEquals(7, Reader.Remaining);
  Reader.GetThree;
  CheckEquals(4, Reader.Remaining);
  Reader.GetInt;
  CheckEquals(0, Reader.Remaining);

  Reader.GetChar;
  CheckEquals(0, Reader.Remaining);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestChunkedGetRemaining;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $03, $04, $FF, $05, $FE, $FE, $06, $FE, $FE, $FE]);
  Reader.ChunkedReadingMode := True;

  CheckEquals(3, Reader.Remaining);

  Reader.GetChar;
  Reader.GetShort;
  CheckEquals(0, Reader.Remaining);

  Reader.GetChar;
  CheckEquals(0, Reader.Remaining);

  Reader.NextChunk;
  CheckEquals(7, Reader.Remaining);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestNextChunk;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $02, $FF, $03, $04, $5, $FF, $06]);
  Reader.ChunkedReadingMode := True;

  CheckEquals(0, Reader.Position);

  Reader.NextChunk;
  CheckEquals(3, Reader.Position);

  Reader.NextChunk;
  CheckEquals(7, Reader.Position);

  Reader.NextChunk;
  CheckEquals(8, Reader.Position);

  Reader.NextChunk;
  CheckEquals(8, Reader.Position);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestNextChunkNotInChunkedReadingMode;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $02, $FF, $03, $04, $5, $FF, $06]);

  CheckException(Reader.NextChunk, EInvalidOpException);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestNextChunkWithChunkedReadingToggledInBetween;
var
  Reader: TEoReader;
begin
  Reader := CreateReader([$01, $02, $FF, $03, $04, $5, $FF, $06]);

  CheckEquals(0, Reader.Position);

  Reader.ChunkedReadingMode := True;
  Reader.NextChunk;
  Reader.ChunkedReadingMode := False;
  CheckEquals(3, Reader.Position);

  Reader.ChunkedReadingMode := True;
  Reader.NextChunk;
  Reader.ChunkedReadingMode := False;
  CheckEquals(7, Reader.Position);

  Reader.ChunkedReadingMode := True;
  Reader.NextChunk;
  Reader.ChunkedReadingMode := False;
  CheckEquals(8, Reader.Position);

  Reader.ChunkedReadingMode := True;
  Reader.NextChunk;
  Reader.ChunkedReadingMode := False;
  CheckEquals(8, Reader.Position);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestUnderRead;
var
  Reader: TEoReader;
begin
  // See: https://github.com/Cirras/eo-protocol/blob/master/docs/chunks.md#1-under-read
  Reader := CreateReader([$7C, $67, $61, $72, $62, $61, $67, $65, $FF, $CA, $31]);
  Reader.ChunkedReadingMode := True;

  CheckEquals(123, Reader.GetChar);
  Reader.NextChunk;
  CheckEquals(12345, Reader.GetShort);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestOverRead;
var
  Reader: TEoReader;
begin
  // See: https://github.com/Cirras/eo-protocol/blob/master/docs/chunks.md#2-over-read
  Reader := CreateReader([$FF, $7C]);
  Reader.ChunkedReadingMode := True;

  CheckEquals(0, Reader.GetInt);
  Reader.NextChunk;
  CheckEquals(123, Reader.GetShort);

  FreeAndNil(Reader);
end;

procedure TTestEoReader.TestDoubleRead;
var
  Reader: TEoReader;
begin
  // See: https://github.com/Cirras/eo-protocol/blob/master/docs/chunks.md#3-double-read
  Reader := CreateReader([$FF, $7C, $CA, $31]);

  // Reading all 4 bytes of the input data
  CheckEquals(790222478, Reader.GetInt);

  // Activating chunked mode and seeking to the first break byte with nextChunk(),
  // which actually takes our Reader position backwards.
  Reader.ChunkedReadingMode := True;
  Reader.NextChunk;

  CheckEquals(123, Reader.GetChar);
  CheckEquals(12345, Reader.GetShort);

  FreeAndNil(Reader);
end;

{ TEoWriterTest }

procedure TTestEoWriter.TestAddByte;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddByte($00);
  Bytes := Writer.ToByteArray;

  CheckEquals(1, Length(Bytes));
  CheckEquals($00, Bytes[0]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddBytes;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddBytes([$00, $FF]);
  Bytes := Writer.ToByteArray;

  CheckEquals(2, Length(Bytes));
  CheckEquals($00, Bytes[0]);
  CheckEquals($FF, Bytes[1]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddChar;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddChar(123);
  Bytes := Writer.ToByteArray;

  CheckEquals(1, Length(Bytes));
  CheckEquals($7C, Bytes[0]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddShort;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddShort(12345);
  Bytes := Writer.ToByteArray;

  CheckEquals(2, Length(Bytes));
  CheckEquals($CA, Bytes[0]);
  CheckEquals($31, Bytes[1]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddThree;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddThree(10000000);
  Bytes := Writer.ToByteArray;

  CheckEquals(3, Length(Bytes));
  CheckEquals($B0, Bytes[0]);
  CheckEquals($3A, Bytes[1]);
  CheckEquals($9D, Bytes[2]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddInt;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddInt(2048576040);
  Bytes := Writer.ToByteArray;

  CheckEquals(4, Length(Bytes));
  CheckEquals($7F, Bytes[0]);
  CheckEquals($7F, Bytes[1]);
  CheckEquals($7F, Bytes[2]);
  CheckEquals($7F, Bytes[3]);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddString('foo');
  Bytes := Writer.ToByteArray;

  CheckEquals('foo', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddFixedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedString('bar', 3);
  Bytes := Writer.ToByteArray;

  CheckEquals('bar', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddPaddedFixedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedString('bar', 6, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('barÿÿÿ', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddPaddedWithPerfectFitFixedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedString('bar', 3, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('bar', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddEncodedString('foo');
  Bytes := Writer.ToByteArray;

  CheckEquals('^0g', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddFixedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedEncodedString('bar', 3);
  Bytes := Writer.ToByteArray;

  CheckEquals('[>k', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddPaddedFixedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedEncodedString('bar', 6, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('ÿÿÿ-l=', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddPaddedWithPerfectFitFixedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.AddFixedEncodedString('bar', 3, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('[>k', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddString('aÿz');
  Bytes := Writer.ToByteArray;

  CheckEquals('ayz', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedFixedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddFixedString('aÿz', 3);
  Bytes := Writer.ToByteArray;

  CheckEquals('ayz', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedPaddedFixedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddFixedString('aÿz', 6, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('ayzÿÿÿ', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddEncodedString('aÿz');
  Bytes := Writer.ToByteArray;

  CheckEquals('S&l', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedFixedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddFixedEncodedString('aÿz', 3);
  Bytes := Writer.ToByteArray;

  CheckEquals('S&l', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddSanitizedPaddedFixedEncodedString;
var
  Writer: TEoWriter;
  Bytes: TArray<Byte>;
begin
  Writer := TEoWriter.Create;
  Writer.StringSanitizationMode := True;
  Writer.AddFixedEncodedString('aÿz', 6, True);
  Bytes := Writer.ToByteArray;

  CheckEquals('ÿÿÿ%T>', FromBytes(Bytes));

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddNumbersOnBoundary;
var
  Writer: TEoWriter;
begin
  Writer := TEoWriter.Create;

  Writer.AddByte($FF);
  Writer.AddChar(EoCharMax - 1);
  Writer.AddShort(EoShortMax - 1);
  Writer.AddThree(EoThreeMax - 1);
  Writer.AddInt(EoIntMax - 1);

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddNumbersExceedingLimit;
var
  Writer: TEoWriter;
begin
  Writer := TEoWriter.Create;

  try
    Writer.AddByte(256);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddChar(EoCharMax);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddShort(EoShortMax);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddThree(EoThreeMax);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddInt(EoIntMax);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestAddFixedStringWithIncorrectLength;
var
  Writer: TEoWriter;
begin
  Writer := TEoWriter.Create;

  try
    Writer.AddFixedString('foo', 2);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddFixedString('foo', 2, True);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddFixedString('foo', 4);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddFixedEncodedString('foo', 2);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddFixedEncodedString('foo', 2, True);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  try
    Writer.AddFixedEncodedString('foo', 4);
    Fail('Expected EArgumentAception');
  except
    Check(ExceptObject is EArgumentException, 'Expected EArgumentAception');
  end;

  FreeAndNil(Writer);
end;

procedure TTestEoWriter.TestLength;
var
  Writer: TEoWriter;
  I: Integer;
begin
  Writer := TEoWriter.Create;

  CheckEquals(0, Writer.Length);

  Writer.AddString('Lorem ipsum dolor sit amet');
  CheckEquals(26, Writer.Length);

  for I := 27 to 100 do begin
    Writer.AddByte($FF);
  end;

  CheckEquals(100, Writer.Length);

  FreeAndNil(Writer);
end;

initialization
  RegisterTest(TTestEncodingUtilities.Suite);
  RegisterTest(TTestEoReader.Suite);
  RegisterTest(TTestEoWriter.Suite);

end.
