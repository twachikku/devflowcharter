{  
   Copyright (C) 2006 The devFlowcharter project.
   The initial author of this file is Michal Domagala.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}

unit LocalizationManager;

interface

{$R ENGLISH_LOC.RES}

uses
   System.Classes, System.IniFiles;

const
   BUTTON       = 1;
   MENU_ITEM    = 2;
   DIALOG       = 3;
   GROUP_BOX    = 4;
   EDIT_HINT    = 5;
   LABELL       = 6;
   RADIO_BUTTON = 7;
   CHECK_BOX    = 8;
   SPEED_BUTTON = 9;
   EDIT_TEXT    = 10;
   
type

   Ti18Manager = class(TObject)
      private
         FRepository: TStringList;
      public
         constructor Create;
         destructor Destroy; override;
         function GetString(const AKey: string): string;
         function LoadDefaultLabels: integer;
         function GetFormattedString(const AKey: string; Args: array of const): string;
         function LoadStaticLabels(const AFileName: string): integer;
         function LoadDynamicLabels(const AFileName: string; const AClearRepository: boolean = false): integer;
         function LoadAllLabels(const AFilename: string): integer;
   end;

implementation

uses
   Vcl.StdCtrls, Vcl.Forms, System.SysUtils, Vcl.Dialogs, WinApi.Windows, Vcl.Menus,
   Vcl.Buttons, System.StrUtils, Vcl.Controls, System.IOUtils, Base_Form, ApplicationCommon;

type
   THackControl = class(TControl);

constructor Ti18Manager.Create;
begin
   inherited Create;
   FRepository := TStringList.Create;
end;

destructor Ti18Manager.Destroy;
begin
   FRepository.Free;
   inherited Destroy;
end;

// this function load labels that are needed all the time during application use (e.g. error message to be displayed
// on incorrect action); in ini file section names with dynamic labels don't end with 'Form'
function Ti18Manager.LoadDynamicLabels(const AFileName: string; const AClearRepository: boolean = false): integer;
var
   keys, sections: TStringList;
   i: integer;
   iniFile: TIniFile;
begin
   result := 0;
   if FileExists(AFileName) then
   begin
      sections := TStringList.Create;
      keys := TStringList.Create;
      iniFile := TIniFile.Create(AFilename);
      try
         iniFile.ReadSections(sections);
         if sections.Count > 0 then
         begin
            if AClearRepository then
               FRepository.Clear;
            FRepository.Sorted := false;
            for i := 0 to sections.Count-1 do
            begin
               if not EndsText('Form', sections[i]) then
               begin
                  iniFile.ReadSectionValues(sections[i], keys);
                  FRepository.AddStrings(keys);
                  result := result + keys.Count;
                  keys.Clear;
               end
            end;
         end;
      finally
         keys.Free;
         sections.Free;
         iniFile.Free;
      end;
   end;
   FRepository.Sort;
end;

// this function load labels that are to be used only once (e.g. button caption); after labelling visual component,
// such label is no longer needed; it is important to call this function when all application's forms are already created;
// in ini file section names with static labels end with 'Form' - one section for each application form
function Ti18Manager.LoadStaticLabels(const AFileName: string): integer;
var
   comp: TComponent;
   i, a, pos: integer;
   keys, sections: TStringList;
   baseForm: TBaseForm;
   value, lName, field: string;
   iniFile: TIniFile;
begin
   result := 0;
   if FileExists(AFileName) then
   begin
      sections := TStringList.Create;
      keys := TStringList.Create;
      iniFile := TIniFile.Create(AFilename);
      try
         iniFile.ReadSections(sections);
         if sections.Count > 0 then
         begin
            for i := 0 to sections.Count-1 do
            begin
               iniFile.ReadSectionValues(sections[i], keys);
               comp := Application.FindComponent(sections[i]);
               if comp is TBaseForm then
               begin
                  baseForm := TBaseForm(comp);
                  for a := 0 to keys.Count-1 do
                  begin
                     field := '';
                     lName := keys.Names[a];
                     pos := System.Pos('.', lName);
                     if pos > 0 then
                     begin
                        field := Copy(lName, pos+1, MAXINT);
                        SetLength(lName, pos-1);
                     end;
                     comp := baseForm.FindComponent(lName);
                     if comp <> nil then
                     begin
                        value := keys.ValueFromIndex[a];
                        if SameText(field, 'Caption') then
                        begin
                           if comp is TMenuItem then
                              TMenuItem(comp).Caption := value
                           else if comp is TControl then
                              THackControl(comp).Caption := value;
                        end
                        else if SameText(field, 'Text') then
                        begin
                           if comp is TControl then
                              THackControl(comp).Text := value;
                        end
                        else if SameText(field, 'Hint') then
                        begin
                           if comp is TControl then
                              TControl(comp).Hint := value;
                        end
                        else if SameText(field, 'Filter') then
                        begin
                           if comp is TOpenDialog then
                              TOpenDialog(comp).Filter := value;
                        end
                        else
                        begin
                           case comp.Tag of
                              BUTTON:       TButton(comp).Caption := value;
                              MENU_ITEM:    TMenuItem(comp).Caption := value;
                              DIALOG:       TOpenDialog(comp).Filter := value;
                              GROUP_BOX:    TGroupBox(comp).Caption := value;
                              EDIT_HINT:    TEdit(comp).Hint := value;
                              EDIT_TEXT:    TEdit(comp).Text := value;
                              LABELL:       TLabel(comp).Caption := value;
                              RADIO_BUTTON: TRadioButton(comp).Caption := value;
                              CHECK_BOX:    TCheckBox(comp).Caption := value;
                              SPEED_BUTTON: TSpeedButton(comp).Hint := value;
                           end;
                        end;
                     end;
                  end;
                  baseForm.Localize(keys);
                  result := result + keys.Count;
               end;
               keys.Clear;
            end;
         end;
      finally
         sections.Free;
         keys.Free;
         iniFile.Free;
      end;
   end;
end;

function Ti18Manager.LoadDefaultLabels: integer;
var
   resStream: TResourceStream;
   langFile, errMsg: string;
begin
   errMsg := '';
   langFile := TPath.GetTempPath + 'english.lng';
   resStream := TResourceStream.Create(Hinstance, 'DEFAULT_LOCALIZATION_FILE', 'LNG_FILE');
   try
      try
         resStream.SaveToFile(langFile);
         result := LoadAllLabels(langFile);
      except on E: EFCreateError do
         begin
            errMsg := 'Could not create default translation file ' + langFile + ':' + CRLF + E.Message;
            result := 0;
         end;
      end;
   finally
      System.SysUtils.DeleteFile(langFile);
      resStream.Free;
   end;
   if result = 0 then
   begin
      if errMsg = '' then
         errMsg := 'Failed to load translation labels.';
      Application.MessageBox(PChar(errMsg), 'IO Error', MB_ICONERROR);
   end;
end;

function Ti18Manager.GetString(const AKey: string): string;
begin
   result := FRepository.Values[AKey];
   if result = '' then
      result := AKey;
end;



function Ti18Manager.LoadAllLabels(const AFilename: string): integer;
begin
   FRepository.Clear;
   result := LoadStaticLabels(AFilename);
   result := result + LoadDynamicLabels(AFilename);
end;

function Ti18Manager.GetFormattedString(const AKey: string; Args: array of const): string;
begin
   result := Format(GetString(AKey), Args);
end;

end.