unit Next.Core.Void;

interface

uses
  System.SysUtils;

type
  EVoidException = class(Exception);

  TVoid = class sealed
  public
    constructor Create();
  end;

const Void: TVoid = nil;

implementation

{ TVoid }

constructor TVoid.Create;
begin
  raise EVoidException.Create('TVoid should never be instantiated, use Void constant instead');
end;

end.
