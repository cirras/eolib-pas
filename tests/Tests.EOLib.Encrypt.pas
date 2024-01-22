unit Tests.EOLib.Encrypt;

interface

uses
  TestFramework;

type
  TTestEncryptionUtilities = class(TTestCase)
    procedure TestInterleave;
    procedure TestDeinterleave;
    procedure TestFlipMsb;
    procedure TestSwapMultiples;
  end;

  TTestServerVerificationUtilities = class(TTestCase)
    procedure TestServerVerificationHash;
  end;

implementation

uses
  SysUtils,
  EOLib.Data,
  EOLib.Encrypt;

type
  TStringData = record
    Input: string;
    Expected: string;
  end;

  TNumberData = record
    Input: Integer;
    Expected: Integer;
  end;

const
  InterleaveData: array[0..6] of TStringData = (
    (
      Input:    'Hello, World!';
      Expected: 'H!edlllroo,W '
    ),
    (
      Input:    'We''re ¼ of the way there, so ¾ is remaining.';
      Expected: 'W.eg''nrien i¼a moefr  tshie  ¾w aoys  t,heer'
    ),
    (
      Input:    '64² = 4096';
      Expected: '6649²0 4= '
    ),
    (
      Input:    '© FÒÖ BÃR BÅZ 2014';
      Expected: '©4 1F0Ò2Ö  ZBÅÃBR '
    ),
    (
      Input:    'Öxxö Xööx "Lëïth Säë" - "Ÿ"';
      Expected: 'Ö"xŸx"ö  -X ö"öëxä S" Lhëtï'
    ),
    (
      Input:    'Padded with 0xFFÿÿÿÿÿÿÿÿ';
      Expected: 'Pÿaÿdÿdÿeÿdÿ ÿwÿiFtFhx 0'
    ),
    (
      Input:    'This string contains NUL'#0' (value 0) and a € (value 128)';
      Expected: 'T)h8i2s1  seturlianvg(  c€o nat adinnas  )N0U Le'#0'u l(av'
    )
  );

  DeinterleaveData: array[0..6] of TStringData = (
    (
      Input:    'Hello, World!';
      Expected: 'Hlo ol!drW,le'
    ),
    (
      Input:    'We''re ¼ of the way there, so ¾ is remaining.';
      Expected: 'W''e¼o h a hr,s  srmiig.nnae i¾o eetywetf  re'
    ),
    (
      Input:    '64² = 4096';
      Expected: '6²=4960  4'
    ),
    (
      Input:    '© FÒÖ BÃR BÅZ 2014';
      Expected: '©FÖBRBZ2140 Å Ã Ò '
    ),
    (
      Input:    'Öxxö Xööx "Lëïth Säë" - "Ÿ"';
      Expected: 'Öx öx"ët ä"-""Ÿ  ëShïL öXöx'
    ),
    (
      Input:    'Padded with 0xFFÿÿÿÿÿÿÿÿ';
      Expected: 'Pde ih0FÿÿÿÿÿÿÿÿFx twdda'
    ),
    (
      Input:    'This string contains NUL'#0' (value 0) and a € (value 128)';
      Expected: 'Ti tigcnan U'#0'(au )ada€(au 2)81elv   n 0elv LNsito nrssh'
    )
  );

  FlipMsbData: array[0..6] of TStringData = (
    (
      Input:    'Hello, World!';
      Expected: 'Èåììï¬'#$A0'×ïòìä¡'
    ),
    (
      Input:    'We''re ¼ of the way there, so ¾ is remaining.';
      Expected: '×å§òå'#$A0'<'#$A0'ïæ'#$A0'ôèå'#$A0'÷áù'#$A0'ôèåòå¬'#$A0'óï'#$A0'>'#$A0'éó'#$A0'òåíáéîéîç®'
    ),
    (
      Input:    '64² = 4096';
      Expected: '¶´2'#$A0'½'#$A0'´°¹¶'
    ),
    (
      Input:    '© FÒÖ BÃR BÅZ 2014';
      Expected: ')' + string(#$A0) + 'ÆRV'#$A0'ÂCÒ'#$A0'ÂEÚ'#$A0'²°±´'
    ),
    (
      Input:    'Öxxö Xööx "Lëïth Säë" - "Ÿ"';
      Expected: 'Vøøv'#$A0'Øvvø'#$A0'¢Ìkoôè'#$A0'Ódk¢'#$A0#$AD#$A0'¢'#$1F'¢'
    ),
    (
      Input:    'Padded with 0xFFÿÿÿÿÿÿÿÿ';
      Expected: 'Ðáääåä'#$A0'÷éôè'#$A0'°øÆÆ'#$7F#$7F#$7F#$7F#$7F#$7F#$7F#$7F
    ),
    (
      Input:    'This string contains NUL'#0' (value 0) and a € (value 128)';
      Expected: 'Ôèéó'#$A0'óôòéîç'#$A0'ãïîôáéîó'#$A0'ÎÕÌ'#0#$A0'¨öáìõå'#$A0'°©'#$A0'áîä'#$A0'á'#$A0'€'#$A0'¨öáìõå'#$A0'±²¸©'
    )
  );

  SwapMultiplesData: array[0..6] of TStringData = (
    (
      Input:    'Hello, World!';
      Expected: 'Heoll, lroWd!'
    ),
    (
      Input:    'We''re ¼ of the way there, so ¾ is remaining.';
      Expected: 'Wer''e ¼ fo the way there, so ¾ is remaining.'
    ),
    (
      Input:    '64² = 4096';
      Expected: '64² = 4690'
    ),
    (
      Input:    '© FÒÖ BÃR BÅZ 2014';
      Expected: '© FÒÖ ÃBR BÅZ 2014'
    ),
    (
      Input:    'Öxxö Xööx "Lëïth Säë" - "Ÿ"';
      Expected: 'Ööxx Xxöö "Lëïth Säë" - "Ÿ"'
    ),
    (
      Input:    'Padded with 0xFFÿÿÿÿÿÿÿÿ';
      Expected: 'Padded with x0FFÿÿÿÿÿÿÿÿ'
    ),
    (
      Input:    'This string contains NUL'#0' (value 0) and a € (value 128)';
      Expected: 'This stirng ocntains NUL'#0' (vaule 0) and a € (vaule 128)'
    )
  );

  ServerVerificationHashData: array[0..14] of TNumberData = (
    (Input: 0;              Expected: 114000),
    (Input: 1;              Expected: 115191),
    (Input: 2;              Expected: 229432),
    (Input: 5;              Expected: 613210),
    (Input: 12345;          Expected: 266403),
    (Input: 100000;         Expected: 145554),
    (Input: 5000000;        Expected: 339168),
    (Input: 11092003;       Expected: 112773),
    (Input: 11092004;       Expected: 112655),
    (Input: 11092005;       Expected: 112299),
    (Input: 11092110;       Expected: 11016),
    (Input: 11092111;       Expected: -2787),
    (Input: 11111111;       Expected: 103749),
    (Input: 12345678;       Expected: -32046),
    (Input: EoThreeMax - 1; Expected: 105960)
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

{ TTestEncryptionUtilities }

procedure TTestEncryptionUtilities.TestInterleave;
var
  Data: TStringData;
  Bytes: TArray<Byte>;
  Interleaved: string;
begin
  for Data in InterleaveData do begin
    Bytes := ToBytes(Data.Input);
    Interleave(Bytes);

    Interleaved := FromBytes(Bytes);

    CheckEquals(Data.Expected, Interleaved);
  end;
end;

procedure TTestEncryptionUtilities.TestDeinterleave;
var
  Data: TStringData;
  Bytes: TArray<Byte>;
  Deinterleaved: string;
begin
  for Data in DeinterleaveData do begin
    Bytes := ToBytes(Data.Input);
    Deinterleave(Bytes);

    Deinterleaved := FromBytes(Bytes);

    CheckEquals(Data.Expected, Deinterleaved);
  end;
end;

procedure TTestEncryptionUtilities.TestFlipMsb;
var
  Data: TStringData;
  Bytes: TArray<Byte>;
  FlippedMsb: string;
begin
  for Data in FlipMsbData do begin
    Bytes := ToBytes(Data.Input);
    FlipMsb(Bytes);

    FlippedMsb := FromBytes(Bytes);

    CheckEquals(Data.Expected, FlippedMsb);
  end;
end;

procedure TTestEncryptionUtilities.TestSwapMultiples;
var
  Data: TStringData;
  Bytes: TArray<Byte>;
  SwappedMultiples: string;
begin
  for Data in SwapMultiplesData do begin
    Bytes := ToBytes(Data.Input);
    SwapMultiples(Bytes, 3);

    SwappedMultiples := FromBytes(Bytes);

    CheckEquals(Data.Expected, SwappedMultiples);
  end;
end;

{ TTestServerVerificationUtilities }

procedure TTestServerVerificationUtilities.TestServerVerificationHash;
var
  Data: TNumberData;
  Challenge: Integer;
begin
  for Data in ServerVerificationHashData do begin
    Challenge := ServerVerificationHash(Data.Input);

    CheckEquals(Data.Expected, Challenge);
  end;
end;

initialization
  RegisterTest(TTestEncryptionUtilities.Suite);
  RegisterTest(TTestServerVerificationUtilities.Suite);

end.

