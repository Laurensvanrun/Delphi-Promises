unit Next.Core.FailureReason;

interface

uses
  System.SysUtils;

type
  { We have to make our Exception-object reference counted (through IFailureReason)
    because we can have multiple promises refering the same exception object.
    The best solution should be to clone the Exception object, but this is not
    possible (it can be a custom descendant with all kind of fields). However,
    we do clone the same exception object for the rare cases where the user
    calls Await multiple times on the same promise. Although this is an indication
    of an error in the code flow, it can happen and we want our promise to be
    as immutable as it can be and copy the same JavaScript/TypeScript behavior
    as good as possible.

    Using this solution we can make the following situation work:

      P1 = Promise.Resolve(1).ThenBy (raise)
      P2 = P1.ThenBy(3)

      P1.State = psRejected
      P1.Fail(function (E: Exception) begin ShowMessage(E.Message) end)

      P2.State = psRejected
      P2.Fail(function (E: Exception) begin ShowMessage(E.Message) end)

    If the user re-raises an exception, we must remove it from our internal
    IFailureReason-object to prevent that we get a dangling pointer there.
    }
  IFailureReason = interface
  ['{DFDBBCD0-EA8B-4982-AECE-2610CFFE3DA2}']
    function GetReason: Exception;
    property Reason: Exception read GetReason;
    function DetachExceptionObject: Exception;
  end;

  EFailureReasonAlreadyRaised = class(Exception);

  TFailureReason = class(TInterfacedObject, IFailureReason)
  private
    FReasonClone: Exception;
    FReason: Exception;

    function DetachExceptionObject: Exception;
    function Clone(E: Exception): Exception;
  protected
    function GetReason: Exception;
  public
    constructor Create(const AReason: TObject);
    destructor Destroy; override;
  end;

implementation

{ TFailureReason }

function TFailureReason.DetachExceptionObject: Exception;
begin
  //First time detach the original exception and clone the exception
  //for the case that somebody calls Await multiple times on a rejected
  //promise.
  if Assigned(FReason) then begin
    FReasonClone := Clone(FReason);
    Result := FReason;
    FReason := nil;
  end else
    Result := Clone(FReasonClone);
end;

function TFailureReason.Clone(E: Exception): Exception;
begin
  Result := E.ClassType.Create as Exception;
  Result.Message := E.Message;
  Result.HelpContext := E.HelpContext;
end;

constructor TFailureReason.Create(const AReason: TObject);
begin
  if AReason is Exception then
    FReason := Exception(AReason)
  else
    FReason := Exception.Create('Promise rejected with unknown Exception (nil?)');
end;

destructor TFailureReason.Destroy;
begin
  if Assigned(FReason) then
    FreeAndNil(FReason);
  if Assigned(FReasonClone) then
    FreeAndNil(FReasonClone);
  inherited;
end;

function TFailureReason.GetReason: Exception;
begin
  Result := FReason;
end;

end.
