unit Next.Core.TestVoid;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestVoid = class(TObject)
  public
    [Test]
    procedure WillRaiseConstruction;
    [Test]
    procedure VoidIsNull;
  end;

implementation

uses
  Next.Core.Void;

{ TTestVoid }

procedure TTestVoid.VoidIsNull;
begin
  Assert.IsNull(Void);
end;

procedure TTestVoid.WillRaiseConstruction;
begin
  Assert.WillRaise(procedure begin TVoid.Create; end);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoid);
end.

