unit Next.Core.FailureReason;

interface

uses
  System.SysUtils;

type
  { We have to make our Exception-object reference counted (through IFailureReason)
    because we can have multiple promises refering the same exception object.
    The best solution should be to clone the Exception object, but this is not
    possible (it can be a custom descendant with all kind of fields).

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

  TFailureReason = class(TInterfacedObject, IFailureReason)
  private
    FReason: Exception;

    function DetachExceptionObject: Exception;
  protected
    function GetReason: Exception;
  public
    constructor Create(const AReason: TObject);
    destructor Destroy; override;
  end;

implementation

{ TFailureReason }

{ TFailureReason }

function TFailureReason.DetachExceptionObject: Exception;
begin
  Result := FReason;
  FReason := nil;
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
  inherited;
end;

function TFailureReason.GetReason: Exception;
begin
  Result := FReason;
end;

end.
