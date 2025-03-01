{ Utilities for EO packets. }
unit EOLib.Packet;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
  {$H+}
  {$WARNINGS OFF}
{$ENDIF}

{$R-}
{$Q-}

interface

type
  { A class for generating packet sequences. }
  TPacketSequencer = class
  private
    FStart: Cardinal;
    FCounter: Cardinal;
    procedure SetSequenceStart(Start: Cardinal);

  public
    { Constructs a new @code(TPacketSequencer) with the provided sequence start value.

      @param(Start The sequence start value) }
    constructor Create(Start: Cardinal);

    { Returns the next sequence value, updating the sequence counter in the process.

      @bold(Note:) This is not a monotonic operation. The sequence counter increases from 0 to 9
      before looping back around to 0.

      @returns(The next sequence value) }
    function NextSequence: Cardinal;

    { The sequence start, also known as the "starting counter ID". }
    property SequenceStart: Cardinal read FStart write SetSequenceStart;
  end;

  { A record representing the sequence start value sent with the ACCOUNT_REPLY server packet.

    @seeAlso(TAccountReplyServerPacket) }
  TAccountReplySequenceStart = record
  private
    FValue: Cardinal;

  public
    { Creates an instance of @code(TAccountReplySequenceStart) from the value sent with the
      ACCOUNT_REPLY server packet.

      @param(Value The sequence_start char value sent with the ACCOUNT_REPLY server packet)
      @seeAlso(TAccountReplyServerPacketReplyCodeDataDefault.SequenceStart) }
    class function FromValue(Value: Cardinal): TAccountReplySequenceStart; static;

    { Creates an instance of @code(TAccountReplySequenceStart) with a random value in the range
      (0-240).

      @returns(An instance of @code(TAccountReplySequenceStart)) }
    class function Generate: TAccountReplySequenceStart; static;

    class operator Implicit(SequenceStart: TAccountReplySequenceStart): Cardinal;

    { The sequence start value. }
    property Value: Cardinal read FValue;
  end;

  { A class representing the sequence start value sent with the INIT_INIT server packet.

    @seeAlso(TInitInitServerPacket) }
  TInitSequenceStart = record
  private
    FValue: Cardinal;
    FSeq1: Cardinal;
    FSeq2: Cardinal;

  public
    { Creates an instance of @code(TInitSequenceStart) from the values sent with the INIT_INIT
      server packet.

      @param(Seq1 The seq1 byte value sent with the INIT_INIT server packet)
      @param(Seq2 The seq2 byte value sent with the INIT_INIT server packet)
      @seeAlso(TInitInitServerPacketReplyCodeDataOk.Seq1)
      @seeAlso(TInitInitServerPacketReplyCodeDataOk.Seq2)}
    class function FromInitValues(Seq1: Cardinal; Seq2: Cardinal): TInitSequenceStart; static;

    { Creates an instance of @code(TInitSequenceStart) with a random value in the range (0-1757).

      @returns(An instance of @code(TInitSequenceStart)) }
    class function Generate: TInitSequenceStart; static;

    class operator Implicit(SequenceStart: TInitSequenceStart): Cardinal;

    { The sequence start value. }
    property Value: Cardinal read FValue;

    { The seq1 byte value sent with the INIT_INIT server packet.

      @seeAlso(TInitInitServerPacketReplyCodeDataOk.Seq1) }
    property Seq1: Cardinal read FSeq1;

    { The seq2 byte value sent with the INIT_INIT server packet.

      @seeAlso(TInitInitServerPacketReplyCodeDataOk.Seq2) }
    property Seq2: Cardinal read FSeq2;
  end;

  { A class representing the sequence start value sent with the CONNECTION_PLAYER server packet.

    @seeAlso(TConnectionPlayerServerPacket) }
  TPingSequenceStart = record
  private
    FValue: Cardinal;
    FSeq1: Cardinal;
    FSeq2: Cardinal;

  public
    { Creates an instance of @code(TPingSequenceStart) from the values sent with the
      CONNECTION_PLAYER server packet.

      @param(Seq1 The seq1 short value sent with the CONNECTION_PLAYER server packet)
      @param(Seq2 The seq2 char value sent with the CONNECTION_PLAYER server packet)
      @seeAlso(TConnectionPlayerServerPacket.Seq1)
      @seeAlso(TConnectionPlayerServerPacket.Seq2)}
    class function FromPingValues(Seq1: Cardinal; Seq2: Cardinal): TPingSequenceStart; static;

    { Creates an instance of @code(TPingSequenceStart) with a random value in the range (0-1757).

      @returns(An instance of @code(TPingSequenceStart)) }
    class function Generate: TPingSequenceStart; static;

    class operator Implicit(SequenceStart: TPingSequenceStart): Cardinal;

    { The sequence start value. }
    property Value: Cardinal read FValue;

    { The seq1 short value sent with the CONNECTION_PLAYER server packet.

      @seeAlso(TConnectionPlayerServerPacket.Seq1) }
    property Seq1: Cardinal read FSeq1;

    { The seq2 char value sent with the CONNECTION_PLAYER server packet.

      @seeAlso(TConnectionPlayerServerPacket.Seq2) }
    property Seq2: Cardinal read FSeq2;
  end;

implementation

uses
  Math,
  EOLib.Data;

// FPC uses a Mersenne Twister algorithm to simulate randomness.
// Delphi uses a Linear Congruential generator.
//
// For consistency, we've rolled our own Delphi-compatible LCG.
//
// See:
//   - https://www.freepascal.org/docs-html/rtl/system/random.html
//   - https://en.wikipedia.org/wiki/Linear_congruential_generator
function InternalRandom(From: Integer; To_: Integer): Integer;
var
  Range: Integer;
begin
  Range := Abs(From - To_);
  RandSeed := Cardinal(RandSeed) * 134775813 + 1;
  Result := Integer(Cardinal(RandSeed) * Int64(Range) shr 32) + Min(From, To_);
end;

{ TPacketSequencer }

constructor TPacketSequencer.Create(Start: Cardinal);
begin
  FStart := Start;
end;

function TPacketSequencer.NextSequence: Cardinal;
begin
  Result := FStart + FCounter;
  FCounter := (FCounter + 1) mod 10;
end;

procedure TPacketSequencer.SetSequenceStart(Start: Cardinal);
begin
  FStart := Start;
end;

{ TAccountReplySequenceStart }

class function TAccountReplySequenceStart.FromValue(Value: Cardinal): TAccountReplySequenceStart;
begin
  Result.FValue := Value;
end;

class function TAccountReplySequenceStart.Generate: TAccountReplySequenceStart;
begin
  Result.FValue := InternalRandom(0, 241);
end;

class operator TAccountReplySequenceStart.Implicit(SequenceStart: TAccountReplySequenceStart): Cardinal;
begin
  Result := SequenceStart.FValue;
end;

{ TInitSequenceStart }

class function TInitSequenceStart.FromInitValues(Seq1: Cardinal; Seq2: Cardinal): TInitSequenceStart;
begin
  Result.FValue := Seq1 * 7 + Seq2 - 13;
  Result.FSeq1 := Seq1;
  Result.FSeq2 := Seq2;
end;

class function TInitSequenceStart.Generate: TInitSequenceStart;
var
  Seq1Max: Integer;
  Seq1Min: Integer;
begin
  Result.FValue := InternalRandom(0, 1758);

  Seq1Max := (Result.FValue + 13) div 7;
  Seq1Min := Max(0, (Result.FValue - (EoCharMax - 1) + 13 + 6) div 7);

  Result.FSeq1 := InternalRandom(Seq1Min, Seq1Max);
  Result.FSeq2 := Integer(Result.FValue) - Integer(Result.Seq1) * 7 + 13;
end;

class operator TInitSequenceStart.Implicit(SequenceStart: TInitSequenceStart): Cardinal;
begin
  Result := SequenceStart.FValue;
end;

{ TPingSequenceStart }

class function TPingSequenceStart.FromPingValues(Seq1: Cardinal; Seq2: Cardinal): TPingSequenceStart;
begin
  Result.FValue := Seq1 - Seq2;
  Result.FSeq1 := Seq1;
  Result.FSeq2 := Seq2;
end;

class function TPingSequenceStart.Generate: TPingSequenceStart;
begin
  Result.FValue := InternalRandom(0, 1758);
  Result.FSeq1 := Result.FValue + Cardinal(InternalRandom(0, EoCharMax));
  Result.FSeq2 := Integer(Result.FSeq1) - Integer(Result.FValue);
end;

class operator TPingSequenceStart.Implicit(SequenceStart: TPingSequenceStart): Cardinal;
begin
  Result := SequenceStart.FValue;
end;

initialization
  Randomize;

end.
