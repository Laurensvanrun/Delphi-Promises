unit Next.Core.TestFailureReason;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFailureReason = class(TObject)
  public
    [Test]
    procedure FailureReason;
    [Test]
    procedure NoValidException;
    [Test]
    procedure DetachException;
  end;

implementation

uses
  Next.Core.FailureReason, Next.Core.Test.Assert, System.SysUtils;

{ TTestFailureReason }

procedure TTestFailureReason.DetachException;
var
  LReason: IFailureReason;
  LException: Exception;
begin
  LReason := TFailureReason.Create(ETestException.Create('My Exception'));

  //This should not leak memory, because the except (catch) fill free the exception object
  LException := LReason.Reason;
  LReason.DetachExceptionObject;
  try
    raise LException;
  except
    on E: Exception do;
  end;

  Assert.IsNull(LReason.Reason);
end;

procedure TTestFailureReason.FailureReason;
var
  LReason: IFailureReason;
begin
  LReason := TFailureReason.Create(ETestException.Create('My Exception'));

  Assert.IsNotNull(LReason.Reason);
  Assert.AreEqual('My Exception', LReason.Reason.Message);
  Assert.InheritsFrom(LReason.Reason.ClassType, ETestException);
end;

procedure TTestFailureReason.NoValidException;
var
  LReason: IFailureReason;
begin
  LReason := TFailureReason.Create(nil);

  Assert.IsNotNull(LReason.Reason);
  Assert.InheritsFrom(LReason.Reason.ClassType, Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFailureReason);
end.
