unit Tests.EOLib.Packet;

interface

uses
  TestFramework;

type
  TTestPacketSequencer = class(TTestCase)
    procedure TestNextSequence;
    procedure TestSetSequenceStart;
  end;

  TTestAccountReplySequenceStart = class(TTestCase)
    procedure TestFromValue;
    procedure TestGenerate;
    procedure TestImplicit;
  end;

  TTestInitSequenceStart = class(TTestCase)
  private
    const
      Value = 1511;
      Seq1 = 184;
      Seq2 = 236;
  published
    procedure TestFromInitValues;
    procedure TestGenerate;
    procedure TestImplicit;
  end;

  TTestPingSequenceStart = class(TTestCase)
  private
    const
      Value = 1511;
      Seq1 = 1531;
      Seq2 = 20;
  published
    procedure TestFromPingValues;
    procedure TestGenerate;
    procedure TestImplicit;
  end;

implementation

uses
  SysUtils,
  EOLib.Packet;

{ TTestPacketSequencer }

procedure TTestPacketSequencer.TestNextSequence;
var
  SequenceStart: TAccountReplySequenceStart;
  Sequencer: TPacketSequencer;
  I: Integer;
begin
  SequenceStart := TAccountReplySequenceStart.FromValue(123);
  Sequencer := TPacketSequencer.Create(SequenceStart);

  // Counter should increase 9 times and then wrap around
  for I := 0 to 9 do begin
    CheckEquals(123 + I, Sequencer.NextSequence);
  end;

  // Counter should have wrapped around
  CheckEquals(123, Sequencer.NextSequence);

  FreeAndNil(Sequencer);
end;

procedure TTestPacketSequencer.TestSetSequenceStart;
var
  SequenceStart: TAccountReplySequenceStart;
  Sequencer: TPacketSequencer;
begin
  SequenceStart := TAccountReplySequenceStart.FromValue(100);
  Sequencer := TPacketSequencer.Create(SequenceStart);

  CheckEquals(100, Sequencer.NextSequence);

  SequenceStart := TAccountReplySequenceStart.FromValue(200);
  Sequencer.SequenceStart := SequenceStart;

  // When the sequence start is updated, the counter should not reset
  CheckEquals(201, Sequencer.NextSequence);

  FreeAndNil(Sequencer);
end;

{ TTestAccountReplySequenceStart }

procedure TTestAccountReplySequenceStart.TestFromValue;
var
  SequenceStart: TAccountReplySequenceStart;
begin
  SequenceStart := TAccountReplySequenceStart.FromValue(22);
  CheckEquals(22, SequenceStart.Value);
end;

procedure TTestAccountReplySequenceStart.TestGenerate;
var
  SequenceStart: TAccountReplySequenceStart;
begin
  RandSeed := 123;

  SequenceStart := TAccountReplySequenceStart.Generate;

  CheckEquals(207, SequenceStart.Value);
end;

procedure TTestAccountReplySequenceStart.TestImplicit;
var
  SequenceStart: TAccountReplySequenceStart;
begin
  SequenceStart := TAccountReplySequenceStart.FromValue(22);
  CheckEquals(SequenceStart.Value, Cardinal(SequenceStart));
end;

{ TTestInitSequenceStart }

procedure TTestInitSequenceStart.TestFromInitValues;
var
  SequenceStart: TInitSequenceStart;
begin
  SequenceStart := TInitSequenceStart.FromInitValues(Seq1, Seq2);
  CheckEquals(SequenceStart.Value, Value);
  CheckEquals(SequenceStart.Seq1, Seq1);
  CheckEquals(SequenceStart.Seq2, Seq2);
end;

procedure TTestInitSequenceStart.TestGenerate;
var
  SequenceStart: TInitSequenceStart;
begin
  RandSeed := 123;

  SequenceStart := TInitSequenceStart.Generate;

  CheckEquals(SequenceStart.Value, Value);
  CheckEquals(SequenceStart.Seq1, Seq1);
  CheckEquals(SequenceStart.Seq2, Seq2);
end;

procedure TTestInitSequenceStart.TestImplicit;
var
  SequenceStart: TInitSequenceStart;
begin
  SequenceStart := TInitSequenceStart.FromInitValues(Seq1, Seq2);
  CheckEquals(SequenceStart.Value, Cardinal(SequenceStart));
end;

{ TTestPingSequenceStart }

procedure TTestPingSequenceStart.TestFromPingValues;
var
  SequenceStart: TPingSequenceStart;
begin
  SequenceStart := TPingSequenceStart.FromPingValues(Seq1, Seq2);
  CheckEquals(SequenceStart.Value, Value);
  CheckEquals(SequenceStart.Seq1, Seq1);
  CheckEquals(SequenceStart.Seq2, Seq2);
end;

procedure TTestPingSequenceStart.TestGenerate;
var
  SequenceStart: TPingSequenceStart;
begin
  RandSeed := 123;

  SequenceStart := TPingSequenceStart.Generate;

  CheckEquals(SequenceStart.Value, Value);
  CheckEquals(SequenceStart.Seq1, Seq1);
  CheckEquals(SequenceStart.Seq2, Seq2);
end;

procedure TTestPingSequenceStart.TestImplicit;
var
  SequenceStart: TPingSequenceStart;
begin
  SequenceStart := TPingSequenceStart.FromPingValues(Seq1, Seq2);
  CheckEquals(SequenceStart.Value, Cardinal(SequenceStart));
end;

initialization
  RegisterTest(TTestPacketSequencer.Suite);
  RegisterTest(TTestAccountReplySequenceStart.Suite);
  RegisterTest(TTestInitSequenceStart.Suite);
  RegisterTest(TTestPingSequenceStart.Suite);

end.
