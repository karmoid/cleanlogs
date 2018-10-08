{-----------------------------------------------------------------------------
 Unit Name: BaseObjects
 Author:    Marc
 Date:      01-oct.-2006
 Purpose:   Définition des classes de base manipulées par le programme de
            nettoyage des fichiers.
 History:
            Version 0.9Alpha bour Brink's France fait le week-end chez moi.
            Pour supprimer tous les fichiers oubliés dans les répertoires
            BAMBOO
-----------------------------------------------------------------------------}
unit BaseObjects;

interface
uses
  Classes,
  Contnrs,
  Windows,
  Sysutils;

var
  FileSeq : Cardinal = 0;

Type
  tKindAccess = (kaCreated, kaAccessed, kaModified);
  tKindPeriod = (kpDay, kpWeek, kpMonth, kpYear);
  tTaillePLancher = (Kilo=1024, Mega=1024*1024, Giga=1024*1024*1024);
  tOptions = (opRecursif,opExecute,opForce,opReadonly);
  tPredefinedV = (opTimeStmp, opDate, opHeure, opQuantieme, opJour, opMois, OpAnnee);

const
  AccessLib : array[tKindAccess] of string = ('creation', 'dernier acces', 'modification');
  PeriodLib : array[tKindPeriod] of string  = ('jour', 'semaine', 'mois', 'annee');
  SetOptionsLib : array[tOptions] of string = ('recursif','execute','force','includereadonly');
  ClrOptionsLib : array[tOptions] of string = ('plat','simulation','confirmation','noreadonly');
  PredefValue : array [tPredefinedv] of string = ('now','date','time', 'dayofyear', 'day', 'month', 'year');

type
  tOptionset = set of tOptions;

  tCleanException = class(Exception)
  end;

  tFichier = class
  private
    fID : Cardinal;
    fFileName : TFileName;
    fDates : array[tKindAccess] of TDateTime;
    fFileSize : Cardinal;
    fPath : string;
    procedure SetFileName(const Value: TFileName);
    procedure SetID(const Value: Cardinal);
    class function GetNextID : Integer;
    procedure SetFileSize(const Value: Cardinal);
    class function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
    function GetTailleToString: string;
    function GetKiloToString: string;
    function GetOctetToString: string;
    procedure SetPath(const Value: string);
    function GetDates(const Index: tKindAccess): TDateTime;
    procedure SetDates(const Index: tKindAccess; Value : TDateTime);
  public
    { Identifiant unique du fichier dans le programme. Séquenceur Run-Time }
    property ID : Cardinal read FID write SetID;
    { Nom complet du fichir en UNC ou en format Lettre+Chemin }
    property FileName : tFileName read FFileName write SetFileName;
    { Date de création du fichier }
    property DateCreated : TDateTime Index kaCreated read GetDates write SetDates;
    { Date de dernier accès au fichier }
    property DateAccessed : TDateTime Index kaAccessed read GetDates write SetDates;
    { Date de dernière modification }
    property DateModified : TDateTime Index kaModified read GetDates write SetDates;
    property Dates [const Index : tKindAccess] : TDateTime read GetDates write SetDates;
    { Taille liberée par la suppression du fichier }
    property FileSize : Cardinal read FFileSize write SetFileSize;
    { Chemin d'accès au fichier }
    property Path : string read FPath write SetPath;
    { Taille représentée sous forme de chaîne }
    property TailleToString : string read GetTailleToString;
    { Taille en Kilo Octets représentée sous forme de chaîne }
    property KiloToString: string read GetKiloToString;
    { Taille en octets représentée sous forme de chaîne }
    property OctetToString: string read GetOctetToString;
    { Construction de l'objet par un record Findfirst/Findnext }
    constructor Create(const RecInfo : TSearchRec);
  end;

  tCritere = class
  private
    fAccess : tKindAccess;
    fPeriod : tKindPeriod;
    fValue  : Integer;
    fSpec   : TStrings;
    procedure SetAccess(const Value: tKindAccess);
    procedure SetPeriod(const Value: tKindPeriod);
    procedure SetSpec(const Value: TStrings);
    procedure SetValue(const Value: Integer);
  public
    { Type d'accès à tester }
    property Access : tKindAccess read FAccess write SetAccess;
    { Type de période à tester }
    property Period : tKindPeriod read FPeriod write SetPeriod;
    { Nombre de période à tester }
    property Value  : Integer read FValue write SetValue;
    { Spécification de fichier à prendre en compte }
    property Spec   : TStrings read FSpec write SetSpec;
    { Constructeur du critère de sélection }
    constructor Create(StValue: string);
    { Destructeur de l'objet }
    destructor Destroy; override;
    { Indique si le fichier doit être pris en compte }
    function AcceptFile(Fic : tFichier) : Boolean;
    { Donne une représentation correcte de l'objet }
    function ToString : string;
  end;

  tTask = class(TObjectList)
  private
    fListCriteres : TObjectList;
    fPath         : string;
    fOptionsSet   : tOptionSet;
    bOptionsFOund : tOptionSet;
    fTraceFile    : TFileName;
    bTraceFile    : Boolean;
    function GetOptionsSet(const Index: tOptions): Boolean;
    procedure SetOptionsSet(const Index: tOptions; const Value: Boolean);
    procedure ExploiteOneCritere(var Crit : string);
    function GetOptionToString: string;
    function getOptionSet: tOptionset;
    procedure SetOptionSet(const Value: tOptionset);
    procedure SetTraceFile(const value: TFileName);
    function ExprimeValue(const Value : string) : string;
    function pad0(const value : string; const len : integer) : string;

  public
    property ListCriteres : TObjectList read fListCriteres;
    property Path         : string read fPath write fpath;
    property OptionSet : tOptionset read getOptionSet write SetOptionSet;
    property OptionsSet [const Index: tOptions] : Boolean read getOptionsSet write SetOptionsSet;
    property TraceFile    : TFileName read fTraceFile write SetTraceFile;
    property OptionToString : string read GetOptionToString;
    constructor Create; overload;
    constructor Create(Value : string); overload;
    destructor Destroy; override;
    procedure ExploiteCritere(Crit : string);
    procedure ExploitOption(Opt : string);
    function GetValueTraceFile(const value : string) : string;
    function GetValueOptionSet(const value : tOptionSet) : tOptionSet;
    procedure Test;
  end;

implementation

uses DateUtils;

{ tFichier }

constructor tFichier.Create(const RecInfo: TSearchRec);
begin
  inherited Create;
  ID := GetNextID;
  FileName := RecInfo.Name;
  // writeln('accessed');
  DateAccessed := FileTimeToDateTime(RecInfo.FindData.ftLastAccessTime);
  // writeln('created');
  DateCreated := FileTimeToDateTime(RecInfo.FindData.ftCreationTime);
  // writeln('Modified');
  DateModified := FileTimeToDateTime(RecInfo.FindData.ftLastWriteTime);
  FileSize := (RecInfo.FindData.nFileSizeHigh SHL 32) or RecInfo.FindData.nFileSizeLow;
end;

class function tFichier.GetNextID: Integer;
begin
  Inc(FileSeq);
  Result := FileSeq;
end;

procedure tFichier.SetFileName(const Value: TFileName);
begin
  FFileName := Value;
end;

procedure tFichier.SetFileSize(const Value: Cardinal);
begin
  FFileSize := Value;
end;

procedure tFichier.SetID(const Value: Cardinal);
begin
  FID := Value;
end;

class function tfichier.FileTimeToDateTime(FileTime: TFileTime): TDateTime;
{=================================================================}
{ fonction permettant de convertir des date de type FileTime      }
{ en Date de type DateTime                                        }
{=================================================================}
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
  YY,MM,DD : Word;
begin
  FileTimeToLocalFileTime(FileTime, LocalFileTime);
  FileTimeToSystemTime(LocalFileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
  DeCodeDate (Result,YY,MM,DD);
end;



function tFichier.GetTailleToString: string;
begin
  if FileSize>Ord(Giga) then
    Result := IntToStr(FileSize div Ord(Giga))+','+
              IntToStr((FileSize mod Ord(Giga)) div Ord(Mega))+'GiB'
  else if FileSize>Ord(Mega) then
    Result := IntToStr(FileSize div Ord(Mega))+','+
              IntToStr((FileSize mod Ord(Mega)) div Ord(Kilo))+'MiB'
  else if FileSize>Ord(Kilo) then
    Result := IntToStr(FileSize div Ord(Kilo))+','+
              IntToStr((FileSize mod Ord(Kilo)))+'KiB'
  else
    Result := IntToStr(FileSize)+'B';
end;

function tFichier.GetKiloToString: string;
begin
  if FileSize>Ord(Kilo) then
    Result := IntToStr(FileSize div Ord(Kilo))+','+
              IntToStr((FileSize mod Ord(Kilo)))+'KiB'
  else
    Result := IntToStr(FileSize)+'B';
end;

function tFichier.GetOctetToString: string;
begin
  Result := IntToStr(FileSize)+'B';
end;

procedure tFichier.SetPath(const Value: string);
begin
  FPath := Value;
end;

function tFichier.GetDates(const Index: tKindAccess): TDateTime;
begin
  Result := fDates[Index];
end;

procedure tFichier.SetDates(const Index: tKindAccess; Value: TDateTime);
begin
  fDates[Index] := Value;
end;

{ tCritere }

function tCritere.AcceptFile(Fic: tFichier): Boolean;
var Limite : Integer;
// var Lib : array[boolean] of string = ('refused','accepted');
begin
  case Period of
    kpDay   : Limite := Value;
    kpMonth : Limite := Value*31;
    kpWeek  : Limite := Value*7;
    kpYear  : Limite := Value*365;
  end;
  Result := DaysBetween(Date,Fic.Dates[Access])>=Limite;
  // writeln('AcceptFile for ['+Fic.FileName+'] DaysBetween['+inttostr(DaysBetween(Date,Fic.Dates[Access]))+'] Date['+ FormatDateTime('dd/mm/yyyy',Fic.Dates[Access])+'] Limite['+IntToStr(Limite)+'] -> '+Lib[Result])
end;

constructor tCritere.Create(StValue: string);
begin
  Value := -1;
  Access := kaAccessed;             { Le plus restrictif }
  fSpec := TStringList.Create;
  StValue := Trim(StValue);
  StValue := StringReplace(StValue,' ','',[rfReplaceAll]);
  if StValue<>'' then
  begin
    if (StValue[1]='(') and
      (Length(StValue)>2) and
      (StValue[3]=')') Then
    begin
      case UpCase(StValue[2]) of
        'A' : Access := kaAccessed;
        'M' : Access := kaModified;
        'C' : Access := kaCreated;
        else raise tCleanException.Create('Mauvais code d''accès fichier :['+Upcase(StValue[2]));
      end;
      Delete(StValue,1,3);
    end;
    if (StValue[1]='+') and
      (Length(StValue)>2) and
      (Pos('[',StValue)<>0) and
      TryStrToInt(Copy(StValue,2,Pred(Pred(Pos('[',StValue)))-1),fValue) Then
    begin
      case UpCase(StValue[Pred(Pos('[',StValue))]) of
        'D' : Period := kpDay;
        'W' : Period := kpWeek;
        'M' : Period := kpMonth;
        'Y' : Period := kpYear;
        else raise tCleanException.Create('Mauvais code de période :['+UpCase(StValue[Pred(Pos('[',StValue))]));
      end;
      Delete(StValue,1,Pred(Pos('[',StValue)));
    end;
    if (StValue[1]='[') and
      (Length(StValue)>2) and
      (StValue[Length(StValue)]=']') Then
    begin
      Delete(StValue,1,1);
      SetLength(StValue,Length(StValue)-1);
      while Pos(';',StValue)<>0 do
      begin
        Spec.Add(Copy(stValue,1,Pred(Pos(';',StValue))));
        Delete(StValue,1,Pos(';',StValue));
      end;
      if StValue<>'' then
        Spec.Add(stValue);
    end
    else
      raise tCleanException.Create('Mauvaise Syntaxe :['+StValue+']');
  end;
end;

destructor tCritere.Destroy;
begin
  fSpec.Free;
  inherited;
end;

procedure tCritere.SetAccess(const Value: tKindAccess);
begin
  FAccess := Value;
end;

procedure tCritere.SetPeriod(const Value: tKindPeriod);
begin
  FPeriod := Value;
end;

procedure tCritere.SetSpec(const Value: TStrings);
begin
  FSpec := Value;
end;

procedure tCritere.SetValue(const Value: Integer);
begin
  FValue := Value;
end;

function tCritere.ToString: string;
begin
  Result := IntToStr(Value)+' '+ PeriodLib[Period]+' par rapport à la date de '+AccessLib[Access];
end;

{ tTask }

constructor tTask.Create(Value: string);
begin
  Create;
  ExploiteCritere(Value);
end;

constructor tTask.Create;
begin
  inherited ;
  fListCriteres := TObjectList.Create;
end;

destructor tTask.Destroy;
begin
  fListCriteres.Free;
  inherited;
end;

procedure tTask.ExploiteCritere(Crit: string);
var LocalCritere : string;
begin
  LocalCritere := Crit;
{  TraceSt.Add('On va exploiter : ['+Crit+']'); }
  while LocalCritere<>'' do
  begin
    ExploiteOneCritere(LocalCritere)
  end;
end;

procedure tTask.ExploiteOneCritere(var Crit: string);
var Critere : tCritere;
var Indice : Integer;
begin
  Indice := Pos(']',Crit);
  if Indice<>0 then
  begin
    Critere := tCritere.Create(Copy(Crit,1,Indice));
    ListCriteres.Add(Critere);
    Crit := Copy(Crit,Succ(Indice),Length(Crit));
//    TraceSt.Add('Critère créé (reste ['+Crit+']) :'+
//            AccessLib[Critere.Access]+
//            ', Valeur('+IntToStr(Critere.Value)+'),'+
//            PeriodLib[Critere.Period]+', Spec{'+Critere.Spec.CommaText+'}');
  end
  else
    Crit:='';
end;

procedure tTask.ExploitOption(Opt: string);
var O : tOptions;
begin
  Opt := ','+Opt+',';
  fOptionsSet := [];
  // writeln('Option: '+Opt);
  for O:= Low(tOptions) to High(TOptions) do
  begin
    if Pos(','+SetOptionsLib[O]+',',Opt)<>0 then
      OptionsSet[O] := True;
    if Pos(','+ClrOptionsLib[O]+',',Opt)<>0 then
      OptionsSet[O] := False;
  end;
end;

function tTask.getOptionSet: tOptionset;
begin
  Result := fOptionsSet;
end;

function tTask.GetOptionsSet(const Index: tOptions): Boolean;
begin
  Result := Index in fOptionsSet;
end;

function tTask.GetOptionToString: string;
var O : tOptions;
begin
  Result := '';
  for O:= Low(tOptions) to High(TOptions) do
  begin
    if O in fOptionsSet then
      Result := Result + SetOptionsLib[O]+', '
    else
      Result := Result + ClrOptionsLib[O]+', ';
  end;
  if Result<>'' then
    Setlength(Result, Length(Result)-2);
end;

procedure tTask.SetOptionSet(const Value: tOptionset);
begin
  fOptionsSet := Value;
end;

procedure tTask.SetOptionsSet(const Index: tOptions; const Value: Boolean);
begin
  if Value then
    fOptionsSet := fOptionsSet + [Index]
  else
    fOptionsSet := fOptionsSet - [Index];
  bOptionsFOund := bOptionsFOund + [Index];
end;

function tTask.pad0(const value : string; const len : integer) : string;
begin
  if Length(Value)<len then
    Result := StringofCHar('0',Len-Length(Value))+Value
  else
    result := Value;
end;

function tTask.ExprimeValue(const Value : string) : string;
var Iter : tPredefinedv;
var D,M,Y : word;
begin
  Decodedate(Date,Y,M,D);
  Result := Value;
  for iter:=low(tPredefinedv) to high(tPredefinedv) do
  begin
    case Iter of
      opTimeStmp : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',formatdatetime('yyyymmdd_hhnnss',now),[rfReplaceAll,rfIgnoreCase]);
      opDate     : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',formatdatetime('yyyymmdd',now),[rfReplaceAll,rfIgnoreCase]);
      opHeure    : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',formatdatetime('hhnnss',now),[rfReplaceAll,rfIgnoreCase]);
      opQuantieme: Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',pad0(inttostr(trunc(date)-trunc(encodedate(Y,1,1))),3),[rfReplaceAll,rfIgnoreCase]);
      opJour     : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',pad0(inttostr(D),2),[rfReplaceAll,rfIgnoreCase]);
      opMois     : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',pad0(inttostr(M),2),[rfReplaceAll,rfIgnoreCase]);
      OpAnnee    : Result := StringReplace(Result,'%'+predefvalue[Iter]+'%',pad0(inttostr(Y),2),[rfReplaceAll,rfIgnoreCase]);
    end;
  end;
end;

procedure tTask.SetTraceFile(const value: TFileName);
begin
  fTraceFile := ExprimeValue(Value);
  bTraceFile := true;
end;

function tTask.GetValueTraceFile(const value : string) : string;
begin
  if bTraceFile then
    Result := TraceFile
  else
    result := Value;
end;

function tTask.GetValueOptionSet(const value : tOptionSet) : tOptionSet;
var Indice: tOptions;
var Pos   : Boolean;
begin
  Result := [];
  for Indice := Low(tOptions) to HIgh(tOptions) do
  begin
    Pos := false;
    if (Indice in bOptionsFOund) then
      Pos := Indice in fOptionsSet
    else
      Pos := Indice in Value;
    if Pos then
      Result := Result + [Indice];
  end;
end;

procedure tTask.Test;
begin
  Assert(ExprimeValue('%date%')=ExprimeValue('%year%')+ExprimeValue('%month%')+
                               ExprimeValue('%day%'));
end;


end.
