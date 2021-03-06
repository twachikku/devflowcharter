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



unit Project;

interface

uses
   WinApi.Windows, Vcl.Graphics, System.Classes, Vcl.ComCtrls, Vcl.Controls, System.Contnrs,
   UserFunction, OmniXML, UserDataType, Main_Block, DeclareList, BaseIterator, CommonTypes,
   CommonInterfaces, BlockTabSheet;

type

   TBaseIteratorFriend = class(TBaseIterator)
   end;

   TProject = class(TInterfacedPersistent, IExportable)
   private
      FGlobalVars: TVarDeclareList;
      FGlobalConsts: TConstDeclareList;
      FIntegerTypesSet: TIntegerTypesSet;
      FRealTypesSet: TRealTypesSet;
      FBoolTypesSet: TBoolTypesSet;
      FOtherTypesSet: TOtherTypesSet;
      FPointerTypesSet: TPointerTypesSet;
      FStructTypesSet: TStructTypesSet;
      FEnumTypesSet: TEnumTypesSet;
      FArrayTypesSet: TArrayTypesSet;
      FStringTypesSet: TStringTypesSet;
      FComponentList: TComponentList;
      FObjectIds: TStringList;
      FObjectIdSeed: integer;
      FMainPage: TBlockTabSheet;
      class var FInstance: TProject;
      procedure SetGlobals;
      function GetComponents(const ASortType: integer = NO_SORT; const AClassName: string = ''): IIterator;
      function GetComponentByName(const AClassName: string; const AName: string): TComponent;
      function GetIWinControlComponent(const AHandle: THandle): IWinControl;
      procedure RefreshZOrder;
      constructor Create;
   public
      Name: string;
      LastUserFunction: TUserFunction;
      property IntegerTypesSet: TIntegerTypesSet read FIntegerTypesSet;
      property BoolTypesSet: TBoolTypesSet read FBoolTypesSet;
      property OtherTypesSet: TOtherTypesSet read FOtherTypesSet;
      property RealTypesSet: TRealTypesSet read FRealTypesSet;
      property PointerTypesSet: TPointerTypesSet read FPointerTypesSet;
      property StructTypesSet: TStructTypesSet read FStructTypesSet;
      property EnumTypesSet: TEnumTypesSet read FEnumTypesSet;
      property ArrayTypesSet: TArrayTypesSet read FArrayTypesSet;
      property StringTypesSet: TStringTypesSet read FStringTypesSet;
      property GlobalVars: TVarDeclareList read FGlobalVars default nil;
      property GlobalConsts: TConstDeclareList read FGlobalConsts default nil;
      class function GetInstance: TProject;
      destructor Destroy; override;
      procedure AddComponent(const AComponent: TComponent);
      function GetComments: IIterator;
      function GetUserFunctions(const ASortType: integer = PAGE_INDEX_SORT): IIterator;
      function GetUserDataTypes: IIterator;
      function GetUserDataType(const ATypeName: string): TUserDataType;
      function GetUserFunction(const AFunctionName: string): TUserFunction;
      procedure ExportToGraphic(const AGraphic: TGraphic);
      procedure ExportToXMLTag(const ATag: IXMLElement);
      function ExportToXMLFile(const AFile: string): TErrorType;
      function ImportFromXMLTag(const ATag: IXMLElement): TErrorType;
      function ImportUserFunctionsFromXML(const ATag: IXMLElement): TErrorType;
      function ImportUserDataTypesFromXML(const ATag: IXMLElement): TErrorType;
      function ImportCommentsFromXML(const ATag: IXMLElement): integer;
      procedure ImportPagesFromXML(const ATag: IXMLElement);
      function GetMainBlock: TMainBlock;
      function GetBottomRight: TPoint;
      procedure PopulateDataTypeCombos;
      procedure RefreshStatements;
      procedure ChangeDesktopColor(const AColor: TColor);
      function CountErrWarn: TErrWarnCount;
      procedure GenerateTree(const ANode: TTreeNode);
      procedure RepaintFlowcharts;
      procedure RepaintComments;
      function GetLibraryList: TStringList;
      function FindObject(const AId: integer): TObject;
      procedure RefreshSizeEdits;
      procedure PopulateDataTypes;
      procedure UpdateZOrder(const AParent: TWinControl);
      function Register(const AObject: TObject; const AId: integer = ID_INVALID): integer;
      procedure UnRegister(const AObject: TObject);
      function GetPage(const ACaption: string; const ACreate: boolean = true): TBlockTabSheet;
      function GetMainPage: TBlockTabSheet;
      function GetActivePage: TBlockTabSheet;
      procedure UpdateHeadersBody(const APage: TTabSheet);
      function GetPageOrder: string;
      function FindMainBlockForControl(const AControl: TControl): TMainBlock;
      function GetProgramHeader: string;
      function GetExportFileName: string;
   end;

implementation

uses
   System.SysUtils, Vcl.Menus, System.StrUtils, System.Types, ApplicationCommon,
   XMLProcessor, Base_Form, LangDefinition, Navigator_Form, SortListDecorator, Base_Block,
   Comment, TabComponent, ParserHelper;

constructor TProject.Create;
begin
   inherited Create;
   FObjectIds := TStringList.Create;
   FComponentList := TComponentList.Create;
end;

destructor TProject.Destroy;
begin
   if GSettings <> nil then
   begin
      if FGlobalVars <> nil then
      begin
         GSettings.ColumnV1Width := FGlobalVars.sgList.ColWidths[0];
         GSettings.ColumnV2Width := FGlobalVars.sgList.ColWidths[1];
         GSettings.ColumnV3Width := FGlobalVars.sgList.ColWidths[2];
         GSettings.ColumnV4Width := FGlobalVars.sgList.ColWidths[3];
         GSettings.ColumnV5Width := FGlobalVars.sgList.ColWidths[4];
      end;
      if FGlobalConsts <> nil then
      begin
         GSettings.ColumnC1Width := FGlobalConsts.sgList.ColWidths[0];
         GSettings.ColumnC2Width := FGlobalConsts.sgList.ColWidths[1];
         GSettings.ColumnC3Width := FGlobalConsts.sgList.ColWidths[2];
      end;
   end;
   while FComponentList.Count > 0 do             // automatic disposing objects that are stored in list by calling list's destructor
      FComponentList[0].Free;                    // will generate EListError exception for pinned comments
   FComponentList.Free;                          // so to destroy FComponentList, objects must be freed in while loop first
   FGlobalVars.Free;
   FGlobalConsts.Free;
   FObjectIds.Free;
   FInstance := nil;
   inherited Destroy;
end;

class function TProject.GetInstance: TProject;
begin
   if FInstance = nil then
   begin
      FInstance := TProject.Create;
      FInstance.SetGlobals;
      FInstance.PopulateDataTypes;
   end;
   result := FInstance;
end;

function TProject.GetPage(const ACaption: string; const ACreate: boolean = true): TBlockTabSheet;
var
   i: integer;
   caption: string;
   pageControl: TPageControl;
begin
   result := nil;
   caption := Trim(ACaption);
   if caption <> '' then
   begin
      pageControl := TInfra.GetMainForm.pgcPages;
      for i := 0 to pageControl.PageCount-1 do
      begin
         if SameCaption(pageControl.Pages[i].Caption, caption) then
         begin
            result := TBlockTabSheet(pageControl.Pages[i]);
            break;
         end;
      end;
      if result = nil then
      begin
         if SameCaption(caption, MAIN_PAGE_MARKER) then
            result := GetMainPage
         else if ACreate then
         begin
            result := TBlockTabSheet.Create(TInfra.GetMainForm);
            result.Caption := caption;
         end;
      end;
   end;
end;

function TProject.GetMainPage: TBlockTabSheet;
begin
   if FMainPage = nil then
      FMainPage := GetPage(i18Manager.GetString(DEF_PAGE_CAPTION_KEY));
   result := FMainPage;
end;

function TProject.GetActivePage: TBlockTabSheet;
begin
   result := TBlockTabSheet(TInfra.GetMainForm.pgcPages.ActivePage);
end;

function TProject.GetExportFileName: string;
begin
   result := Name;
end;

procedure TProject.PopulateDataTypes;
var
   userType: TUserDataType;
   i: integer;
   name: string;
   nativeType: PNativeDataType;
begin
   FIntegerTypesSet := [];
   FRealTypesSet := [];
   FBoolTypesSet := [];
   FOtherTypesSet := [];
   FPointerTypesSet := [];
   FStructTypesSet := [];
   FEnumTypesSet := [];
   FArrayTypesSet := [];
   FStringTypesSet := [];
   Include(FPointerTypesSet, GENERIC_PTR_TYPE);

   if FGlobalVars <> nil then
   begin
      for i := 0 to FGlobalVars.cbType.Items.Count-1 do
      begin
         name := FGlobalVars.cbType.Items[i];
         userType := GetUserDataType(name);
         nativeType := GInfra.GetNativeDataType(name);
         if nativeType <> nil then
         begin
            case nativeType.Kind of
               tpInt:    Include(FIntegerTypesSet, i);
               tpReal:   Include(FRealTypesSet, i);
               tpString: Include(FStringTypesSet, i);
               tpBool:   Include(FBoolTypesSet, i);
               tpPtr:    Include(FPointerTypesSet, i);
            else
               Include(FOtherTypesSet, i);
            end;
         end
         else if userType <> nil then
         begin
            if userType.rbInt.Checked then
               Include(FIntegerTypesSet, i)
            else if userType.rbReal.Checked then
               Include(FRealTypesSet, i)
            else if userType.rbStruct.Checked then
               Include(FStructTypesSet, i)
            else if userType.rbEnum.Checked then
               Include(FEnumTypesSet, i)
            else if userType.rbArray.Checked then
               Include(FArrayTypesSet, i)
            else
               Include(FOtherTypesSet, i);
         end
         else if Assigned(GInfra.CurrentLang.IsPointerType) and GInfra.CurrentLang.IsPointerType(name) then
            Include(FPointerTypesSet, i)
         else
            Include(FOtherTypesSet, i);
      end;
   end;
end;

procedure TProject.AddComponent(const AComponent: TComponent);
begin
   FComponentList.Add(AComponent);
end;

function TProject.GetComments: IIterator;
begin
   result := GetComponents(NO_SORT, TComment.ClassName);
end;

function TProject.GetUserFunctions(const ASortType: integer = PAGE_INDEX_SORT): IIterator;
begin
   result := GetComponents(ASortType, TUserFunction.ClassName);
end;

function TProject.GetUserDataTypes: IIterator;
begin
   result := GetComponents(PAGE_INDEX_SORT, TUserDataType.ClassName);
end;

function TProject.GetComponents(const ASortType: integer = NO_SORT; const AClassName: string = ''): IIterator;
var
   i: integer;
   list: TComponentList;
   listDecor: TSortListDecorator;
begin
   list := TComponentList.Create(false);
   if list.Capacity < FComponentList.Count then
      list.Capacity := FComponentList.Count;
   for i := 0 to FComponentList.Count-1 do
   begin
       if AClassName <> '' then
       begin
          if FComponentList[i].ClassNameIs(AClassName) then
             list.Add(FComponentList[i]);
       end
       else
          list.Add(FComponentList[i]);
   end;
   if (ASortType <> NO_SORT) and (list.Count > 1) then
   begin
      listDecor := TSortListDecorator.Create(list, ASortType);
      listDecor.Sort;
      listDecor.Free;
   end;
   result := TBaseIteratorFriend.Create(list);
end;

function TProject.Register(const AObject: TObject; const AId: integer = ID_INVALID): integer;
var
   idx: integer;
   id: string;
   accepted: boolean;
begin
   id := IntToStr(AId);
   accepted := (AId <> ID_INVALID) and (FObjectIds.IndexOf(id) = -1);
   idx := FObjectIds.IndexOfObject(AObject);
   if idx <> -1 then
   begin
      result := StrToInt(FObjectIds.Strings[idx]);
      if accepted then
         FObjectIds.Strings[idx] := id;
   end
   else
   begin
      if accepted then
         FObjectIds.AddObject(id, AObject)
      else
      begin
         FObjectIds.AddObject(IntToStr(FObjectIdSeed), AObject);
         result := FObjectIdSeed;
         FObjectIdSeed := FObjectIdSeed + 1;
      end;
   end;
   if accepted then
   begin
      if FObjectIdSeed <= AId then
         FObjectIdSeed := AId + 1;
      result := AId;
   end;
end;

procedure TProject.UnRegister(const AObject: TObject);
var
   idx: integer;
begin
   idx := FObjectIds.IndexOfObject(AObject);
   if idx <> -1 then
      FObjectIds.Delete(idx);
end;

function TProject.FindObject(const AId: integer): TObject;
var
   idx: integer;
begin
   result := nil;
   idx := FObjectIds.IndexOf(IntToStr(AId));
   if idx <> -1 then
      result := FObjectIds.Objects[idx];
end;

function TProject.GetPageOrder: string;
var
   i: integer;
   pageControl: TPageControl;
begin
   result := '';
   pageControl := TInfra.GetMainForm.pgcPages;
   for i := 0 to pageControl.PageCount-1 do
   begin
      if i <> 0 then
         result := result + PAGE_LIST_DELIM;
      if GetMainPage = pageControl.Pages[i] then
         result := result + MAIN_PAGE_MARKER
      else
         result := result + pageControl.Pages[i].Caption;
   end;
end;

function TProject.ExportToXMLFile(const AFile: string): TErrorType;
begin
   result := TXMLProcessor.ExportToXMLFile(ExportToXMLTag, AFile);
   if result = errNone then
      TInfra.GetMainForm.AcceptFile(AFile);
end;

procedure TProject.ExportToXMLTag(const ATag: IXMLElement);
var
   itr, iter: IIterator;
   xmlObj: IXMLable;
   i: integer;
   pageControl: TPageControl;
begin

   ATag.SetAttribute(LANG_ATTR, GInfra.CurrentLang.Name);
   ATag.SetAttribute(PAGE_ORDER_ATTR, GetPageOrder);
   if GetMainPage <> GetActivePage then
      ATag.SetAttribute(PAGE_FRONT_ATTR, GetActivePage.Caption);

   if FGlobalVars <> nil then
      FGlobalVars.ExportToXMLTag(ATag);
   if FGlobalConsts <> nil then
      FGlobalConsts.ExportToXMLTag(ATag);

   pageControl := TInfra.GetMainForm.pgcPages;
   for i := 0 to pageControl.PageCount-1 do
      UpdateZOrder(pageControl.Pages[i]);

   iter := GetComponents(PAGE_INDEX_SORT);
   while iter.HasNext do
   begin
      if Supports(iter.Next, IXMLable, xmlObj) and xmlObj.Active then
         xmlObj.ExportToXMLTag(ATag);
   end;

   itr := TBaseFormIterator.Create;
   while itr.HasNext do
      TBaseForm(itr.Next).ExportSettingsToXMLTag(ATag);
   
end;

procedure TProject.ImportPagesFromXML(const ATag: IXMLElement);
var
   pageList, pageName, pageFront: string;
   i, len: integer;
   page, activePage: TTabSheet;
begin
   if ATag <> nil then
   begin
      activePage := nil;
      pageName := '';
      pageFront := ATag.GetAttribute(PAGE_FRONT_ATTR);
      if pageFront = '' then
         activePage := GetMainPage;
      pageList := ATag.GetAttribute(PAGE_ORDER_ATTR);
      len := Length(pageList);
      for i := 1 to len do
      begin
         page := nil;
         if pageList[i] = PAGE_LIST_DELIM then
         begin
            page := GetPage(pageName);
            pageName := '';
         end
         else
         begin
            pageName := pageName + pageList[i];
            if i = len then
               page := GetPage(pageName);
         end;
         if (page <> nil) and (activePage = nil) and SameCaption(page.Caption, pageFront) then
            activePage := page;
      end;
      if activePage <> nil then
         activePage.PageControl.ActivePage := activePage;
   end;
end;

function TProject.ImportFromXMLTag(const ATag: IXMLElement): TErrorType;
var
   itr: IIterator;
   s, langName: string;
begin

   result := errValidate;

   langName := ATag.GetAttribute(LANG_ATTR);
   if GInfra.GetLangDefinition(langName) = nil then
   begin
      Gerr_text := i18Manager.GetFormattedString('LngNoSprt', [langName]);
      exit;
   end;

   if SameText(langName, GInfra.DummyLang.Name) then
      s := 'ChangeLngNone'
   else
      s := 'ChangeLngAsk';
   if (not SameText(GInfra.CurrentLang.Name, langName)) and
      (TInfra.ShowFormattedQuestionBox(s, [Trim(langName), CRLF], MB_YESNO+MB_ICONQUESTION) = IDYES) then
   begin
      GInfra.SetCurrentLang(langName);
{$IFDEF USE_CODEFOLDING}
      TInfra.GetEditorForm.ReloadFoldRegions;
{$ENDIF}
      TInfra.GetEditorForm.SetFormAttributes;
      SetGlobals;
   end;

   if FGlobalConsts <> nil then
      FGlobalConsts.ImportFromXMLTag(ATag);
         
   if GInfra.CurrentLang.EnabledUserDataTypes then
      ImportUserDataTypesFromXML(ATag);

   ImportPagesFromXML(ATag);

   result := ImportUserFunctionsFromXML(ATag);
   if result = errNone then
   begin
      if FGlobalVars <> nil then
         FGlobalVars.ImportFromXMLTag(ATag);
      PopulateDataTypeCombos;
      RefreshSizeEdits;
      RefreshStatements;
      ImportCommentsFromXML(ATag);
      RefreshZOrder;
      itr := TBaseFormIterator.Create;
      while itr.HasNext do
         TBaseForm(itr.Next).ImportSettingsFromXMLTag(ATag);
   end;
end;

procedure TProject.SetGlobals;
var
   l, w: integer;
begin
   w := 0;
   if GInfra.CurrentLang.EnabledVars then
   begin
      if FGlobalVars = nil then
      begin
         FGlobalVars := TVarDeclareList.Create(TInfra.GetDeclarationsForm, 2, 1, DEF_VARLIST_WIDTH, 6, 5, DEF_VARLIST_WIDTH-10);
         FGlobalVars.Caption := i18Manager.GetString('GlobalVars');
         FGlobalVars.SetCheckBoxCol(4);
      end;
   end
   else
   begin
      FGlobalVars.Free;
      FGlobalVars := nil;
   end;
   if GInfra.CurrentLang.EnabledConsts then
   begin
      if FGlobalConsts = nil then
      begin
         if FGlobalVars <> nil then
            l := FGlobalVars.BoundsRect.Right
         else
            l := 2;
         FGlobalConsts := TConstDeclareList.Create(TInfra.GetDeclarationsForm, l, 1, DEF_CONSTLIST_WIDTH, 6, 3, DEF_CONSTLIST_WIDTH-10);
         FGlobalConsts.Caption := i18Manager.GetString('GlobalConsts');
         FGlobalConsts.SetCheckBoxCol(2);
      end;
   end
   else
   begin
      FGlobalConsts.Free;
      FGlobalConsts := nil;
   end;
   if FGlobalVars <> nil then
   begin
      FGlobalVars.AssociatedList := FGlobalConsts;
      w := FGlobalVars.BoundsRect.Right + 16;
      if GSettings <> nil then
      begin
         FGlobalVars.sgList.ColWidths[0] := GSettings.ColumnV1Width;
         FGlobalVars.sgList.ColWidths[1] := GSettings.ColumnV2Width;
         FGlobalVars.sgList.ColWidths[2] := GSettings.ColumnV3Width;
         FGlobalVars.sgList.ColWidths[3] := GSettings.ColumnV4Width;
         FGlobalVars.sgList.ColWidths[4] := GSettings.ColumnV5Width;
      end;
   end;
   if FGlobalConsts <> nil then
   begin
      FGlobalConsts.AssociatedList := FGlobalVars;
      w := FGlobalConsts.BoundsRect.Right + 16;
      if GSettings <> nil then
      begin
         FGlobalConsts.sgList.ColWidths[0] := GSettings.ColumnC1Width;
         FGlobalConsts.sgList.ColWidths[1] := GSettings.ColumnC2Width;
         FGlobalConsts.sgList.ColWidths[2] := GSettings.ColumnC3Width;
      end;
   end;
   if w > 0 then
   begin
      TInfra.GetDeclarationsForm.Constraints.MaxWidth := w;
      TInfra.GetDeclarationsForm.Constraints.MinWidth := w;
   end;
   TInfra.GetMainForm.SetMenu(true);
end;

function TProject.ImportUserFunctionsFromXML(const ATag: IXMLElement): TErrorType;
var
   tag, tag1: IXMLElement;
   header: TUserFunctionHeader;
   body: TMainBlock;
   tmpBlock: TBlock;
   page: TTabSheet;
begin
   result := errNone;
   tag := TXMLProcessor.FindChildTag(ATag, FUNCTION_TAG);
   while (tag <> nil) and (result = errNone) do
   begin
      header := nil;
      body := nil;
      tag1 := TXMLProcessor.FindChildTag(tag, HEADER_TAG);
      if (tag1 <> nil) and GInfra.CurrentLang.EnabledUserFunctionHeader then
      begin
         header := TUserFunctionHeader.Create(TInfra.GetFunctionsForm);
         header.ImportFromXMLTag(tag1);
         header.RefreshTab;
      end;
      tag1 := TXMLProcessor.FindChildTag(tag, BLOCK_TAG);
      if (tag1 <> nil) and GInfra.CurrentLang.EnabledUserFunctionBody then
      begin
         page := GetPage(tag1.GetAttribute(PAGE_CAPTION_ATTR));
         if page = nil then
            page := GetMainPage;
         tmpBlock := TXMLProcessor.ImportFlowchartFromXMLTag(tag1, page, nil, result);
         if tmpBlock is TMainBlock then
            body := TMainBlock(tmpBlock);
      end;
      if result = errNone then
         TUserFunction.Create(header, body)
      else
         header.Free;
      tag := TXMLProcessor.FindNextTag(tag);
   end;
end;

function TProject.ImportUserDataTypesFromXML(const ATag: IXMLElement): TErrorType;
var
   dataType: TUserDataType;
   tag: IXMLElement;
   iter: IIterator;
begin
   result := errNone;
   dataType := nil;
   tag := TXMLProcessor.FindChildTag(ATag, DATATYPE_TAG);
   while tag <> nil do
   begin
      dataType := TUserDataType.Create(TInfra.GetDataTypesForm);
      dataType.ImportFromXMLTag(tag);
      dataType.RefreshTab;
      tag := TXMLProcessor.FindNextTag(tag);
   end;
   if FGlobalVars <> nil then
      TInfra.PopulateDataTypeCombo(FGlobalVars.cbType);
   if dataType <> nil then
   begin
      PopulateDataTypes;
      iter := GetUserDataTypes;
      while iter.HasNext do
      begin
         dataType := TUserDataType(iter.Next);
         dataType.RefreshSizeEdits;
         dataType.RefreshTab;
      end;
   end;
end;

function TProject.ImportCommentsFromXML(const ATag: IXMLElement): integer;
var
   comment: TComment;
   tag: IXMLElement;
   page: TBlockTabSheet;
begin
   result := NO_ERROR;
   tag := TXMLProcessor.FindChildTag(ATag, COMMENT_ATTR);
   while tag <> nil do
   begin
      page := GetPage(tag.GetAttribute(PAGE_CAPTION_ATTR));
      if page = nil then
         page := GetMainPage;
      comment := TComment.CreateDefault(page);
      comment.ImportFromXMLTag(tag, nil);
      tag := TXMLProcessor.FindNextTag(tag);
   end;
end;

function TProject.GetProgramHeader: string;
var
   i: integer;
   comment: TComment;
begin
   result := '';
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TComment then
      begin
         comment := TComment(FComponentList[i]);
         if comment.IsHeader then
         begin
            result := comment.Text;
            if EndsText(CRLF, comment.Text) then
               result := result + CRLF;
            break;
         end;
      end;
   end;
end;

function TProject.GetBottomRight: TPoint;
var
   pnt: TPoint;
   i: integer;
   maxBounds: IMaxBoundable;
begin
   result := Point(0, 0);
   for i := 0 to FComponentList.Count-1 do
   begin
      if Supports(FComponentList[i], IMaxBoundable, maxBounds) then
      begin
         pnt := maxBounds.GetMaxBounds;
         if pnt.X > result.X then
            result.X := pnt.X;
         if pnt.Y > result.Y then
            result.Y := pnt.Y;
      end;
   end;
end;

function TProject.GetIWinControlComponent(const AHandle: THandle): IWinControl;
var
   i: integer;
   winControl: IWinControl;
begin
   result := nil;
   for i := 0 to FComponentList.Count-1 do
   begin
      if Supports(FComponentList[i], IWinControl, winControl) and (winControl.GetHandle = AHandle) then
      begin
         result := winControl;
         break;
      end;
   end;
end;

procedure TProject.UpdateZOrder(const AParent: TWinControl);
var
   winControl: IWinControl;
   hnd: THandle;
   i: integer;
begin
   i := 0;
   if AParent <> nil then
   begin
      hnd := GetWindow(GetTopWindow(AParent.Handle), GW_HWNDLAST);
      while hnd <> 0 do
      begin
         winControl := GetIWinControlComponent(hnd);
         if winControl <> nil then
         begin
            winControl.SetZOrder(i);
            i := i + 1;
         end;
         hnd := GetNextWindow(hnd, GW_HWNDPREV);
      end;
   end;
end;

procedure TProject.RefreshZOrder;
var
   iter: IIterator;
   winControl: IWinControl;
begin
   iter := GetComponents(Z_ORDER_SORT);
   while iter.HasNext do
   begin
      if Supports(iter.Next, IWinControl, winControl) then
         winControl.BringAllToFront;
   end;
end;

procedure TProject.ExportToGraphic(const AGraphic: TGraphic);
var
   pnt: TPoint;
   bitmap: TBitmap;
   page: TBlockTabSheet;
begin
   if AGraphic is TBitmap then
      bitmap := TBitmap(AGraphic)
   else
      bitmap := TBitmap.Create;
   pnt := GetBottomRight;
   bitmap.Width := pnt.X;
   bitmap.Height := pnt.Y;
   page := GetActivePage;
   page.DrawI := false;
   bitmap.Canvas.Lock;
   try
      page.PaintTo(bitmap.Canvas, 0, 0);
   finally
      page.DrawI := true;
      bitmap.Canvas.Unlock;
   end;
   if AGraphic <> bitmap then
   begin
      AGraphic.Assign(bitmap);
      bitmap.Free;
   end;
end;

function TProject.GetMainBlock: TMainBlock;
var
   i: integer;
   func: TUserFunction;
begin
   result := nil;
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if (func.Header = nil) and func.Active then
         begin
            result := func.Body;
            break;
         end;
      end;
   end;
end;

procedure TProject.PopulateDataTypeCombos;
var
   i: integer;
   func: TUserFunction;
begin
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if func.Body <> nil then
            func.Body.PopulateComboBoxes;
      end;
   end;
end;

procedure TProject.ChangeDesktopColor(const AColor: TColor);
var
   i: integer;
   comp: TComponent;
   pgcPages: TPageControl;
begin
   pgcPages := TInfra.GetMainForm.pgcPages;
   for i := 0 to pgcPages.PageCount-1 do
   begin
      pgcPages.Pages[i].Brush.Color := AColor;
      pgcPages.Pages[i].Repaint;
   end;
   for i := 0 to FComponentList.Count-1 do
   begin
      comp := FComponentList[i];
      if comp is TUserFunction then
      begin
         if TUserFunction(comp).Body <> nil then
            TUserFunction(comp).Body.ChangeColor(AColor);
      end
      else if comp is TComment then
         TComment(comp).Color := AColor;
   end;
end;

function TProject.CountErrWarn: TErrWarnCount;
var
   i: integer;
   func: TUserFunction;
   dataType: TUserDataType;
   errWarnCount: TErrWarnCount;
begin
   result.ErrorCount := 0;
   result.WarningCount := 0;
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if func.Active then
         begin
            if func.Header <> nil then
            begin
               case func.Header.GetFocusColor of
                  NOK_COLOR:  Inc(result.ErrorCount);
                  WARN_COLOR: Inc(result.WarningCount);
               end;
            end;
            if func.Body <> nil then
            begin
               errWarnCount := func.Body.CountErrWarn;
               Inc(result.ErrorCount, errWarnCount.ErrorCount);
               Inc(result.WarningCount, errWarnCount.WarningCount);
            end;
         end;
      end
      else if FComponentList[i] is TUserDataType then
      begin
         dataType := TUserDataType(FComponentList[i]);
         if dataType.Active then
         begin
            case dataType.GetFocusColor of
               NOK_COLOR:  Inc(result.ErrorCount);
               WARN_COLOR: Inc(result.WarningCount);
            end;
         end;
      end;
   end;
end;

procedure TProject.GenerateTree(const ANode: TTreeNode);
var
   it, iter: IIterator;
   dataType: TUserDataType;
   mainFunc, func: TUserFunction;
   node: TTreeNode;
begin

   mainFunc := nil;

   if GInfra.CurrentLang.EnabledUserDataTypes then
   begin
      node := ANode.Owner.AddChildObject(ANode, i18Manager.GetString('Structures'), TInfra.GetDataTypesForm);
      it := GetUserDataTypes;
      while it.HasNext do
      begin
         dataType := TUserDataType(it.Next);
         if dataType.Active then
            dataType.GenerateTree(node);
      end;
   end;

   if GInfra.CurrentLang.EnabledVars or GInfra.CurrentLang.EnabledConsts then
      ANode.Owner.AddChildObject(ANode, i18Manager.GetString('GlobalDeclares'), TInfra.GetDeclarationsForm);

   if GInfra.CurrentLang.EnabledUserFunctionHeader then
      node := ANode.Owner.AddChildObject(ANode, i18Manager.GetString('Functions'), TInfra.GetFunctionsForm)
   else
      node := ANode;

   iter := GetUserFunctions;
   while iter.HasNext do
   begin
      func := TUserFunction(iter.Next);
      if func.Active then
      begin
         if func.IsMain and (mainFunc = nil) then
            mainFunc := func
         else
            func.GenerateTree(node);
      end;
   end;

   if mainFunc <> nil then
      mainFunc.GenerateTree(ANode);

end;

procedure TProject.UpdateHeadersBody(const APage: TTabSheet);
var
   i: integer;
   func: TUserFunction;
begin
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if (func.Header <> nil ) and (func.Body <> nil) and (func.Body.Page = APage) then
            func.Header.SetPageCombo(APage.Caption);
      end;
   end;
end;

procedure TProject.RefreshStatements;
var
   i: integer;
   c: byte;
   func: TUserFunction;
begin
   c := GChange;
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if func.Active and (func.Body <> nil) then
            func.Body.RefreshStatements;
      end;
   end;
   NavigatorForm.Invalidate;
   if c = 0 then
      GChange := 0;
end;

function TProject.FindMainBlockForControl(const AControl: TControl): TMainBlock;
var
   i: integer;
   func: TUserFunction;
begin
   result := nil;
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if func.Active and (func.Body <> nil) and (func.Body.Parent = AControl.Parent) and PtInRect(func.Body.BoundsRect, AControl.BoundsRect.TopLeft) then
         begin
            result := func.Body;
            break;
         end;
      end;
   end;
end;

procedure TProject.RepaintComments;
var
   i: integer;
   comment: TComment;
begin
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TComment then
      begin
         comment := TComment(FComponentList[i]);
         if comment.Visible then
            comment.Repaint;
      end;
   end;
end;

procedure TProject.RepaintFlowcharts;
var
   i: integer;
   func: TUserFunction;
begin
   for i := 0 to FComponentList.Count-1 do
   begin
      if FComponentList[i] is TUserFunction then
      begin
         func := TUserFunction(FComponentList[i]);
         if (func.Body <> nil) and func.Body.Visible then
            func.Body.RepaintAll;
      end;
   end;
end;

function TProject.GetLibraryList: TStringList;
var
   libName: string;
   tab: ITabbable;
   iter: IIterator;
begin
   result := TStringList.Create;
   result.CaseSensitive := GInfra.CurrentLang.CaseSensitiveSyntax;
   iter := GetComponents(PAGE_INDEX_SORT);
   while iter.HasNext do
   begin
      if Supports(iter.Next, ITabbable, tab) then
      begin
         libName := tab.GetLibName;
         if (libName <> '') and (result.IndexOf(libName) = -1) then
            result.Add(libName);
      end;
   end;
end;

procedure TProject.RefreshSizeEdits;
var
   i: integer;
   sizeEdit: ISizeEditable;
begin
   if (GlobalVars <> nil) and (GlobalVars.edtSize.Text <> '1') then
      GlobalVars.edtSize.OnChange(GlobalVars.edtSize);
   for i := 0 to FComponentList.Count-1 do
   begin
      if Supports(FComponentList[i], ISizeEditable, sizeEdit) then
         sizeEdit.RefreshSizeEdits;
   end;
end;

function TProject.GetUserDataType(const ATypeName: string): TUserDataType;
begin
   result := TUserDataType(GetComponentByName(TUserDataType.ClassName, ATypeName));
end;

function TProject.GetUserFunction(const AFunctionName: string): TUserFunction;
begin
   result := TUserFunction(GetComponentByName(TUserFunction.ClassName, AFunctionName));
end;

function TProject.GetComponentByName(const AClassName: string; const AName: string): TComponent;
var
   i: integer;
   tab: ITabbable;
begin
   result := nil;
   if Trim(AName) <> '' then
   begin
      for i := 0 to FComponentList.Count-1 do
      begin
         if FComponentList[i].ClassNameIs(AClassName) and Supports(FComponentList[i], ITabbable, tab) then
         begin
            if TInfra.SameStrings(tab.GetName, AName) then
            begin
               result := FComponentList[i];
               break;
            end;
         end;
      end;
   end;
end;

end.

