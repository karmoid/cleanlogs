{ =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Marc Chauffour Brink's
Nettoyage des fichiers traces.

Principe :

On va passer au programme des spécifications de fichiers du genre
*.log, *.trc, *.tmp avec des critères de vieillesse des fichiers.
+3d pour + de 3 jours
+3w pour + de 3 semaines
+3m pour + de 3 mois
+3y pour + de 3 ans

en paramˆtre on a donc juste besoin de connaitre le nom de fichier
contenant les paramètres.

(c) pour tester la date de création
(a) pour tester la date de dernier accès
(m) pour tester la date de dernière modification

[default]
tracefile=\\ssiegebabs01\bamboo\logs
criteres=+3d[*.log;*.trc] +3w[PY*.tmp]

[\\ssiegebabs01\bamboo\logs]
criteres=+3d[*.log;*.trc] +3w[PY*.tmp]

[\\ssiegebabs10\bamboo\logs]
criteres=+3d[*.log;*.trc] +3w[PY*.tmp]
tracefile=\\ssiegebabs01\bamboo\logs
option=recursif|plat

‚volutions :
Possibilit‚ de s‚lectionner les r‚pertoires avec masque.
On pourrait ainsi faire le Menage dans les r‚pertoires temporaire
de la maniŠre suivante :
[\\ssiegebabs01\c$\*\temp]
[\\ssiegebabs01\c$\documents and settings\*\temp]

  =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= }
program cleanlogs;

{$APPTYPE CONSOLE}
{ DONE 5 -oMarc -cOptions : Tester la r‚cursivit‚ et la mettre en place. }
{ DONE 5 -oMarc -cSection [override] Qui permet de forcer un mode simulation par exemple 
                  en cours. Reste le problŠme des options partielle. Actuellement tout ou rien
                  il faudrait savoir si on a ou pas l'option (0,1,2,3) sur deux bits }
{ TODO 5 -oMarc -cAjout de TryRmSubDir }
{ TODO 5 -oMarc -cAjout de [\\ssiegebabs01\bamboo*\temp] ou [c:\documents and settings\*\local settings\temp] }
{ TODO 5 -oMarc -cAjout de makezip avec zipfile= }
{ TODO 5 -oMarc -cPossibilit‚ de purger les zip dans le mˆme .ini avec des critŠres de (nombres ou de date) }

uses
  Classes,
  Contnrs,
  IniFiles,
  SysUtils,
  windows,
//  Crt,
  BaseObjects in 'BaseObjects.pas';

type
  tParameters = (parmTrace, parmCritere, parmOption);
  tDelay = (dDay, dWeek, DMonth, dYear);
  tTypeDate = (dtAccess, dtCreate, dtModified);

var
  TraceF : string;
  TraceSt : TStrings;
  ErrorFound : boolean;

const
  ParametersName : array[tParameters] of string = ('tracefile','criteres','options');
  DefaultSection  = ':default';
  OverrideSection = ':override';

procedure GiveHelp();
begin
  writeln('Usage: cleanlogs NomDeFichier');
end;

var
  Inif : tIniFile;
  Sections : TStringList;
  MaListe : TObjectList;
  MonFichier : tFichier;
  Taille : Cardinal;
  Indice,Idx,I : Integer;
  default: tTask;
  over: tTask;
  workTask : tTask;
  workCrit : tCritere;
  OptionsFind: Integer;
  Fichier : TextFile;
  EtatTrt : string;
  Forced : Byte;
  lError : Integer;
  NbFiles : integer;

function LoadFiles(Path : string; Spec : string) : integer;
var SRec: TSearchRec;
var Hnd : LongWord;
begin
  Result := 0;
  if workTask.OptionsSet[opRecursif] then
    OptionsFind := faDirectory;
  Hnd:=FindFirst(Path+'\*.*', OptionsFind, SRec);
  if Hnd = 0 then
  begin
    repeat
      if (SRec.Name[1]<>'.') and
         ((Srec.FindData.dwFileAttributes and Ord(faDirectory))<>0) then
        Result := Result + LoadFiles(Path+'\'+SRec.Name, Spec);
    until FindNext(SRec) <> 0;
    FindClose(Hnd);
  end;
  OptionsFind := faAnyFile and not (faVolumeID or faDirectory);
  Hnd := FindFirst(Path+'\'+Spec, OptionsFind, SRec);
  if Hnd = 0 then
  begin
    repeat
      MonFichier := tFichier.Create(Srec);
//      writeln('trouv‚:'+Srec.name);
      if WorkCrit.AcceptFile(MonFichier) then
      begin
        MaListe.Add(MonFichier);
        MonFichier.Path := Path;
        Taille := Taille + MonFichier.FileSize;
        Inc(Result);
      end
      else
        MonFichier.Free;
    until FindNext(SRec) <> 0;
    FindClose(Hnd);
  end;
end;

procedure LoadIniData(WTask : tTask; wSections : tStrings);
var Indice : Integer;
begin
  Indice := 0;
  while Indice<Sections.Count do
  begin
    if LowerCase(Sections.Names[Indice])=ParametersName[parmTrace] then
      WTask.TraceFile := Sections.ValueFromIndex[Indice]
    else if LowerCase(Sections.Names[Indice])=ParametersName[parmOption] then
      WTask.ExploitOption(Sections.ValueFromIndex[Indice])
    else if LowerCase(Sections.Names[Indice])=ParametersName[parmCritere] then
      WTask.ExploiteCritere(Sections.ValueFromIndex[Indice]);
    Inc(Indice);
  end;
end;

procedure LogTrace;

  procedure InnerLog;
  var Ix : Integer;
  var Ts: TDateTime;
  begin
    Ts := Now;
    Ix := 0;
    Writeln(Fichier,FormatDateTime('dd/mm/yyyy hh:nn:ss',Ts)+
                    ' | =-=-=-=-=-=-=-=-=-=-= DEBUT DE TRACE =-=-=-=-=-=-=-=-=-=-=');
    while Ix<TraceSt.Count do
    begin
      Writeln(Fichier,TraceSt[Ix]);
      Inc(Ix);
    end;
    Writeln(Fichier,FormatDateTime('dd/mm/yyyy hh:nn:ss',Ts)+
                    ' | =-=-=-=-=-=-=-=-=-=-=-= FIN DE TRACE =-=-=-=-=-=-=-=-=-=-=');
    flush(Fichier);
    Close(Fichier);
  end;

begin
  if TraceSt.Count>0 then
  try
    Assign(Fichier,TraceF);
    Append(Fichier);
    InnerLog;
  except
    Assign(Fichier,TraceF);
    Rewrite(Fichier);
    InnerLog;
  end;
  TraceSt.Clear;
end;

function CheckForce : Boolean;
var MyChar : Char;
begin
  if Forced=0 then
  begin
    WriteLn('sur le chemin : '+workTask.Path);
    WriteLn('Etes vous sur de vouloir supprimer '+IntToStr(MaListe.Count)+
            ' fichiers pour '+IntToStr(Taille div 1024)+' Kilo Octets ? [O/N] ');
    read(MyChar);
    if (UpCase(MyChar) IN ['O','Y']) then
      Forced := 1
    else
      Forced := 2;
  end;
  Result := Forced=1;
end;

begin
  TraceSt := TStringList.Create;
  try
    write('cleanlogs - Nettoyage periodique des fichiers traces. ');
    writeln('V1.05');
    writeln('            Marc Chauffour - Dec. 2011');
    writeln;
    Assign(Output,'');
    Rewrite(Output);
    if ParamCount<>1 then
	begin
      GiveHelp();
	  Halt(1);
	end  
    else
    begin
      default := nil;
      try
        Sections := TStringList.Create();
        try
          Inif := TIniFile.Create(ParamStr(1));
          
          inif.ReadSectionValues(DefaultSection,Sections);
          Default := tTask.Create;
          LoadIniData(default,Sections);
          
          inif.ReadSectionValues(OverrideSection,Sections);
          over := tTask.Create;
          LoadIniData(over,Sections);
          
          inif.ReadSections(Sections);
          Indice := 0;
          while Indice<Sections.Count do
          begin
            if ((Sections[Indice][1])<>':') then
            begin
              workTask := tTask.Create;
              default.Add(workTask);
              workTask.Path := Sections[Indice];
              workTask.TraceFile := default.TraceFile;
              workTask.OptionSet := default.OptionSet;
            end;
            inc(Indice)
          end;
          Idx := 0;
          while Idx<default.Count do
          begin
            workTask := tTask(default[Idx]);
            inif.ReadSectionValues(workTask.Path,Sections);
            LoadIniData(WorkTask,Sections);
            WorkTask.TraceFile := Over.GetValueTraceFile(WorkTask.TraceFile);
            WorkTask.OptionSet := Over.GetValueOptionSet(WorkTask.OptionSet);
            inc(Idx);
          end;
          Inif.Free;
        except on e: Exception do
          TraceSt.Add('Exception: '+E.Message);
        end;
      finally
      end;

	  ErrorFound := False;
      MaListe := TObjectList.Create(True);
      Indice := 0;
      while Indice<default.Count do
      begin
        workTask := tTask(default[Indice]);
        Taille := 0;
        TraceF := workTask.TraceFile;
        Idx := 0;
        NbFiles := 0;
        WriteLn('Chemin:['+WorkTask.Path+']');
        while Idx<workTask.ListCriteres.Count do
        begin
          workCrit := tCritere(workTask.ListCriteres[Idx]);
          I := 0;
          TraceSt.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss',Now)+
                      ' | Path['+workTask.Path +
                      '] - Options[' + workTask.OptionToString+
                      '] - Extensions['+workCrit.Spec.CommaText+
                      '] - Criteres['+WorkCrit.toString+']');
          while I<workCrit.Spec.Count do
          begin
            NbFiles := NbFiles + LoadFiles(workTask.Path, workCrit.Spec[I]);
            Inc(I);
          end;
          Inc(Idx);
          WriteLn('* Fichier(s)['+inttostr(NbFiles)+'] Ko['+IntToStr(Taille div 1024)+']');
          WriteLn;
        end;
        TraceSt.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss',Now)+
                    ' | Fichiers[' + IntToStr(MaListe.Count)+
                    '] - TailleOctets['+IntToStr(Taille)+
                    '] - TailleKiloOctets['+IntToStr(Taille div 1024)+
                    '] - TailleMegaOctets['+IntToStr(Taille div (1024*1024))+
                    '] - TailleGigaOctets['+IntToStr(Taille div (1024*1024*1024))+']');
        Idx := 0;
        Forced := 0;
        while Idx<MaListe.Count do
        begin
          MonFichier := tFichier(MaListe[Idx]);
          if workTask.OptionsSet[opExecute] then
            try
              if workTask.OptionsSet[opForce] or CheckForce then
              begin
                if DeleteFile(pchar(MonFichier.Path+'\'+MonFichier.FileName)) then
                  EtatTrt := 'SUPPRIME'
                else
                begin
                  lError := GetLastError;
                  EtatTrt := '!('+IntToStr(lError)+')-'+SysErrorMessage(lError)+'!';
				  ErrorFound := True;
                end;
              end
              else
              begin
				EtatTrt := 'ABANDON UTILISATEUR';
				ErrorFound := True;
              end;
            except on e: Exception do
			  begin
              EtatTrt := 'ERREUR:'+e.Message;
			  ErrorFound := True;
			  end;
            end
          else
            EtatTrt := 'SIMULE';
			TraceSt.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss',Now)+
                      ' | No['+IntToStr(MonFichier.ID)+
                      '] - Emplacement['+MonFichier.Path+
                      '] - Fichier['+MonFichier.FileName+
                      '] - Creation['+FormatDateTime('dd/mm/yyyy hh:nn:ss',MonFichier.DateCreated)+
                      '] - Modification['+FormatDateTime('dd/mm/yyyy hh:nn:ss',MonFichier.DateModified)+
                      '] - DernierAcces['+FormatDateTime('dd/mm/yyyy hh:nn:ss',MonFichier.DateAccessed)+
                      '] - TailleHR['+MonFichier.TailleToString+
                      '] - KiloOctets['+MonFichier.KiloToString+
                      '] - Action['+EtatTrt+']');
			Inc(Idx);
        end;
        if TraceF<>'' then
          LogTrace;
        inc(Indice);
        MaListe.Clear;
      end;
	  if ErrorFound then
		Halt(1)
	  else
		Halt(0);
    end;
  finally
    TraceSt.Free;
  end;
{

}
end.
