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



unit Functions_Form;

interface

uses
   WinApi.Windows, OmniXML, PageControl_Form, CommonTypes;

type

  TFunctionsForm = class(TPageControlForm)
    procedure miAddClick(Sender: TObject); override;
    procedure pgcTabsChange(Sender: TObject); override;
  public
    { Public declarations }
    function ImportTabsFromXMLTag(const ATag: IXMLElement): TErrorType; override;
    procedure ExportSettingsToXMLTag(const ATag: IXMLElement); override;
    procedure ImportSettingsFromXMLTag(const ATag: IXMLElement); override;
    procedure RefreshTabs; override;
    procedure ResetForm; override;
    procedure AddUserFunction(const ABodyTopLeft: TPoint);
  end;

var
  FunctionsForm: TFunctionsForm;

implementation

{$R *.dfm}

uses
   Vcl.Forms, System.SysUtils, ApplicationCommon, Base_Block, Main_Block, Navigator_Form,
   UserFunction, CommonInterfaces;

procedure TFunctionsForm.miAddClick(Sender: TObject);
begin
   AddUserFunction(TInfra.GetMainForm.GetMainBlockNextTopLeft);
end;

procedure TFunctionsForm.AddUserFunction(const ABodyTopLeft: TPoint);
var
   header: TUserFunctionHeader;
   body: TMainBlock;
begin
   Show;
   body := TMainBlock.Create(GProject.GetActivePage, ABodyTopLeft);
   header := TUserFunctionHeader.Create(Self);
   TUserFunction.Create(header, body);
   if CanFocus then
      SetFocus;
   pgcTabs.ActivePage := header;
   if header.edtName.CanFocus then
      header.edtName.SetFocus;
   header.edtName.OnChange(header.edtName);
   if header.Font.Color <> NOK_COLOR then
      TInfra.UpdateCodeEditor(header);
   GChange := 1;
end;

procedure TFunctionsForm.pgcTabsChange(Sender: TObject);
var
   body: TMainBlock;
begin
   inherited pgcTabsChange(Sender);
   body := TUserFunctionHeader(pgcTabs.ActivePage).UserFunction.Body;
   if (body <> nil) and body.Visible then
   begin
      body.Page.PageControl.ActivePage := body.Page;
      body.Page.Form.ScrollInView(body);
      body.BringAllToFront;
      NavigatorForm.Invalidate;
   end;
end;

procedure TFunctionsForm.ExportSettingsToXMLTag(const ATag: IXMLElement);
var
   header: TUserFunctionHeader;
   val: integer;
begin
   RefreshTabs;
   ATag.SetAttribute('func_win_h', IntToStr(Height));
   if Visible then
   begin
      ATag.SetAttribute('func_win_show', '1');
      ATag.SetAttribute('func_win_x', IntToStr(Left));
      ATag.SetAttribute('func_win_y', IntToStr(Top));
      if pgcTabs.ActivePageIndex <> -1 then
      begin
         header := TUserFunctionHeader(pgcTabs.Pages[pgcTabs.ActivePageIndex]);
         ATag.SetAttribute('func_idx', IntToStr(header.PageIndex));
         val := header.ScrollPos;
         if val > 0 then
            ATag.SetAttribute('func_scroll_v', IntToStr(val));
      end;
      if WindowState = wsMinimized then
         ATag.SetAttribute('func_win_min', '1');
   end;
end;

function TFunctionsForm.ImportTabsFromXMLTag(const ATag: IXMLElement): TErrorType;
begin
   result := GProject.ImportUserFunctionsFromXML(ATag);
end;

procedure TFunctionsForm.ImportSettingsFromXMLTag(const ATag: IXMLElement);
var
   header: TUserFunctionHeader;
   val: integer;
begin
   val := StrToIntDef(ATag.GetAttribute('func_win_h'), -1);
   if val > -1 then
      Height := val;
   if (ATag.GetAttribute('func_win_show') = '1') and GInfra.CurrentLang.EnabledUserFunctionHeader then
   begin
      Position := poDesigned;
      if ATag.GetAttribute('func_win_min') = '1' then
         WindowState := wsMinimized;
      val := StrToIntDef(ATag.GetAttribute('func_win_x'), -1);
      if val > -1 then
         Left := val;
      val := StrToIntDef(ATag.GetAttribute('func_win_y'), -1);
      if val > -1 then
         Top := val;
      val := StrToIntDef(ATag.GetAttribute('func_idx'), -2);
      if (pgcTabs.PageCount > 0) and (val in [0..pgcTabs.PageCount-1]) then
      begin
         pgcTabs.ActivePageIndex := val;
         header := TUserFunctionHeader(pgcTabs.Pages[val]);
         val := StrToIntDef(ATag.GetAttribute('func_scroll_v'), 0);
         if val > 0 then
            header.ScrollPos := val;
      end;
      Show;
   end;
end;

procedure TFunctionsForm.RefreshTabs;
var
   i: integer;
   header: TUserFunctionHeader;
   iter: IIterator;
begin
   inherited;
   for i := 0 to pgcTabs.PageCount-1 do
   begin
      header := TUserFunctionHeader(pgcTabs.Pages[i]);
      TInfra.PopulateDataTypeCombo(header.LocalVars.cbType);
      TInfra.PopulateDataTypeCombo(header.cbType);
      iter := header.GetParameterIterator;
      while iter.HasNext do
         TInfra.PopulateDataTypeCombo(TParameter(iter.Next).cbType);
   end;
end;

procedure TFunctionsForm.ResetForm;
begin
   inherited ResetForm;
   Height := 625;
end;

end.
