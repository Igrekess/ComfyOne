--
--	Created by: Yan Senez
--	Created on: 31/10/2024
--
-- ComfyOne - Use ComfyUI API directly inside Capture One
--
--	Copyright © 2024 Yan Senez Photographie, All Rights Reserved
--

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "Dialog Toolkit Plus" version "1.1.3"
use script "PrefsStorageLib" version "1.1.0"

-- Initialiser les valeurs par défaut sans les chemins
prepare storage for domain "com.yse.comfyONE" default values {server_url:"127.0.0.1:8188", workflow:"", TurboON:true, InpaintON:false, theResolution:"Low Res", fillMaskHole:true, mask_prompt:"background", positive_prompt:"landscape view on a forest", negative_prompt:"", seed_value:"1312", seed_control:"Fixe", denoise_level:"1", maskFill:false, maskBlur:"2", maskExpand:"-1", ctrlAON:true, ctrlA_strength:"0.300", ctrlA_start:"0.000", ctrlA_end:"0.300", ctrlBON:true, ctrlB_strength:"0.300", ctrlB_start:"0.000", ctrlB_end:"0.300", invertMask:false, blurInpaint:"15", blendInpaint:"32", contextExpandPixels:"50", contextExpandFactor:"1.0", ipAdapterON:false, ipAdapter_strength:"0.980", inpaintStrenght:"0.500", inpaintStart:"0.000", inpaintEnd:"0.500", ctrlAImg:(POSIX path of (path to documents folder)), ctrlBImg:(POSIX path of (path to documents folder)), ipAdapterImg:(POSIX path of (path to documents folder))}

property workflowList : {} -- Initialise workflowList comme une liste vide
property seedTypeList : {"Fixe", "Increment", "Decrement", "Random"}

set server_url to value for key "server_url"
log "server_url :" & server_url
set mask_prompt to value for key "mask_prompt"
set positive_prompt to value for key "positive_prompt"
set negative_prompt to value for key "negative_prompt"
set seed_value to value for key "seed_value"
set seed_control to value for key "seed_control"
set denoise_level to value for key "denoise_level"
set ctrlA_strength to value for key "ctrlA_strength"
set ctrlA_start to value for key "ctrlA_start"
set ctrlA_end to value for key "ctrlA_end"
set ctrlB_strength to value for key "ctrlB_strength"
set ctrlB_start to value for key "ctrlB_start"
set ctrlB_end to value for key "ctrlB_end"
set fillMaskHole to value for key "fillMaskHole"
set invertMask to value for key "invertMask"
set blurInpaint to value for key "blurInpaint"
set blendInpaint to value for key "blendInpaint"
set contextExpandPixels to value for key "contextExpandPixels"
set contextExpandFactor to value for key "contextExpandFactor"
set ipAdapter_strength to value for key "ipAdapter_strength"
set workflow to value for key "workflow"
set ipAdapterImg to value for key "ipAdapterImg"
set ctrlBImg to value for key "ctrlBImg"
set ctrlAImg to value for key "ctrlAImg"
set TurboON to value for key "TurboON"
set InpaintON to value for key "InpaintON"
set ipAdapterON to value for key "ipAdapterON"
set ctrlAON to value for key "ctrlAON"
set ctrlBON to value for key "ctrlBON"
set maskFill to value for key "maskFill"
set maskBlur to value for key "maskBlur"
set maskExpand to value for key "maskExpand"
set resolutionOptions to {"Low Res", "Mid Res", "High Res"}
set theResolution to value for key "theResolution"
set inpaintStrenght to value for key "inpaintStrenght"
set inpaintStart to value for key "inpaintStart"
set inpaintEnd to value for key "inpaintEnd"
-- Chargement dynamique des workflows depuis le répertoire /workflows
set workflowFolderPath to POSIX path of (path to me)
set workflowFolderPath to do shell script "dirname " & quoted form of workflowFolderPath
set workflowFolderPath to workflowFolderPath & "/workflows"



try
	set workflowFiles to do shell script "ls " & quoted form of workflowFolderPath & "/*.json"
	set workflowList to paragraphs of workflowFiles
	repeat with i from 1 to count of workflowList
		set item i of workflowList to do shell script "basename " & quoted form of item i of workflowList & " .json"
	end repeat
	log workflowList
on error
	display dialog "Erreur : Impossible de charger les workflows. Assurez-vous que le dossier /workflows existe et contient des fichiers .json." buttons {"OK"} default button "OK"
end try


set windowTitle to "..:: Diffusion Models in Capture One ::.."
set accViewWidth to 660
set spacer to 10
set theTop to spacer


set {theButtons, minWidth} to create buttons {"Cancel", "Generate", "SAVE"} default button 2 given «class btns»:2
if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit

set {createdByLabel, theTop} to create label "* created by yan senez - 2024 - v 0.2 - yansenez.com *" bottom (0) max width accViewWidth control size small size aligns center aligned without bold type
set {theRule7, theTop} to create rule (theTop + spacer) rule width accViewWidth

set {ipAdapterInfoLabel, theTop} to create label "(if you don't upload an image and turn on ipAdapter the selected variant in C1 will be use)" bottom theTop + spacer max width accViewWidth control size small size aligns center aligned without bold type

set {ipAdapterImgPath, ipAdapterImgPathLabel, unusedTop} to create labeled path control ipAdapterImg bottom (theTop) control width accViewWidth / 2 label text "Upload image for ipAdapter :" left inset accViewWidth / 2
set {ipAdapter_strength_Field, ipAdapter_strength_Label, unusedTop, fieldLeft} to create side labeled field ipAdapter_strength placeholder text "" bottom (theTop) total width accViewWidth / 4 - 10 label text "strength :" field left 0 left inset accViewWidth / 2 - accViewWidth / 4
if ipAdapterON is true then
	set {ipAdapterCheckbox, theTop, newWidth} to create checkbox "ON" bottom (theTop) max width accViewWidth / 6 - 10 left inset 0 with initial state
else
	set {ipAdapterCheckbox, theTop, newWidth} to create checkbox "ON" bottom (theTop) max width accViewWidth / 6 - 10 left inset 0 without initial state
end if

set {IPAdapterLabel, theTop} to create label "IP-ADAPTER PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type

set {theRule6, theTop} to create rule (theTop + spacer) rule width accViewWidth

set {CtrNetInfoLabel, theTop} to create label "(if you don't upload an image and turn on controlnet the selected variant in C1 will be use)" bottom theTop + spacer max width accViewWidth control size small size aligns center aligned without bold type

set {ctrlBImgPath, ctrlBImgPathLabel, unusedTop} to create labeled path control ctrlBImg bottom (theTop + spacer) control width accViewWidth / 2 label text "Upload image for controlnet B :" left inset accViewWidth / 2
set {ctrlAImgPath, ctrlAImgPathLabel, theTop} to create labeled path control ctrlAImg bottom (theTop + spacer) control width accViewWidth / 2 label text "Upload image for controlnet A :" left inset 0

set {ctrlB_strength_Field, ctrlB_strength_Label, unusedTop, fieldLeft} to create side labeled field ctrlB_strength placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "Strength :" field left 0
set {ctrlA_strength_Field, ctrlA_strength_Label, theTop, fieldLeft} to create side labeled field ctrlA_strength placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "Strength :" field left 0 left inset accViewWidth / 2

set {ctrlB_end_Field, ctrlB_end_Label, unusedTop, fieldLeft} to create side labeled field ctrlB_end placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "End :" field left 0 left inset accViewWidth / 2
set {ctrlA_end_Field, ctrlA_end_Label, theTop, fieldLeft} to create side labeled field ctrlA_end placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "End :" field left 0

set {ctrlB_start_Field, ctrlB_start_Label, unusedTop, fieldLeft} to create side labeled field ctrlB_start placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "Start :" field left 0 left inset accViewWidth / 2
set {ctrlA_start_Field, ctrlA_start_Label, theTop, fieldLeft} to create side labeled field ctrlA_start placeholder text "" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "Start :" field left 0

if ctrlBON is true then
	set {CtrlNetBCheckbox, unusedTop, newWidth} to create checkbox "ON" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset accViewWidth / 2 with initial state
else
	set {CtrlNetBCheckbox, unusedTop, newWidth} to create checkbox "ON" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset accViewWidth / 2 without initial state
end if
if ctrlAON is true then
	set {CtrlNetACheckbox, theTop, newWidth} to create checkbox "ON" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset 0 with initial state
else
	set {CtrlNetACheckbox, theTop, newWidth} to create checkbox "ON" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset 0 without initial state
end if

set {CtrlNetBLabel, unusedTop} to create label "CONTROLNET B PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned left inset accViewWidth / 2 with bold type
set {CtrlNetALabel, theTop} to create label "CONTROLNET A PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type


set {theRule5, theTop} to create rule (theTop + spacer) rule width accViewWidth


set {inpaintEnd_Field, inpaintEnd_Label, unusedTop, fieldLeft} to create side labeled field inpaintEnd bottom (theTop + spacer) total width accViewWidth / 3 - 10 label text "Inpaint ctrln end :" field left 0 left inset accViewWidth - accViewWidth / 3
set {inpaintStart_Field, inpaintStart_Label, unusedTop, fieldLeft} to create side labeled field inpaintStart bottom (theTop + spacer) total width accViewWidth / 3 - 10 label text "Inpaint ctrln start :" field left 0 left inset accViewWidth / 3
set {inpaintStrenght_Field, inpaintStrenght_Label, theTop, fieldLeft} to create side labeled field inpaintStrenght bottom (theTop + spacer) total width accViewWidth / 3 - 10 label text "Inpaint ctrln strenght :" field left 0

-- Expansion du contexte et contrôle du remplissage
set {contextExpandFactor_Field, contextExpandFactor_Label, unusedTop, fieldLeft} to create side labeled field contextExpandFactor bottom (theTop + spacer) total width accViewWidth / 5 label text "with factor :" field left 0 left inset accViewWidth - accViewWidth / 5
set {contextExpandPixels_Field, contextExpandPixels_Label, unusedTop, fieldLeft} to create side labeled field contextExpandPixels bottom (theTop + spacer) total width accViewWidth / 3 - 25 label text "Context expand :" field left 0 left inset accViewWidth / 2
-- Paramètres de masquage
set {blendInpaint_Field, blendInpaint_Label, unusedTop, fieldLeft} to create side labeled field blendInpaint bottom (theTop + spacer) total width accViewWidth / 4 - 10 label text "Mask Blend:" field left 0 left inset accViewWidth / 4
set {blurInpaint_Field, blurInpaint_Label, theTop, fieldLeft} to create side labeled field blurInpaint bottom (theTop + spacer) total width accViewWidth / 4 - 10 label text "Inpaint Mask Blur:" field left 0

set {InpaintLabel, theTop} to create label "INPAINT PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type


set {theRule4, theTop} to create rule (theTop + spacer) rule width accViewWidth

if invertMask is true then
	set {invertMaskCheckbox, unusedTop, newWidth} to create checkbox "Invert Mask" bottom (theTop + spacer) max width accViewWidth / 3 - 10 left inset accViewWidth - accViewWidth / 7 with initial state
else
	set {invertMaskCheckbox, unusedTop, newWidth} to create checkbox "Invert Mask" bottom (theTop + spacer) max width accViewWidth / 3 - 10 left inset accViewWidth - accViewWidth / 7 without initial state
end if
if fillMaskHole is true then
	set {fillMaskHoleCheckbox, unusedTop, newWidth} to create checkbox "Fill Mask Hole" bottom (theTop + spacer) max width accViewWidth / 3 - 10 left inset (accViewWidth / 3) * 2 + 10 with initial state
else
	set {fillMaskHoleCheckbox, unusedTop, newWidth} to create checkbox "Fill Mask Hole" bottom (theTop + spacer) max width accViewWidth / 3 - 10 left inset (accViewWidth / 3) * 2 + 10 without initial state
end if
set {maskBlur_Field, maskBlur_Label, unusedTop, fieldLeft} to create side labeled field maskBlur placeholder text "" bottom (theTop + spacer) total width accViewWidth / 3 - 10 label text "Mask Blur :" field left 0 left inset accViewWidth / 3
set {maskExpand_Field, maskExpand_Label, theTop, fieldLeft} to create side labeled field maskExpand placeholder text "" bottom (theTop + spacer) total width accViewWidth / 3 - 10 label text "Expand mask :" field left 0

set {mask_prompt_Field, mask_prompt_Label, theTop, fieldLeft} to create side labeled field mask_prompt placeholder text "what you want to target for masking" bottom (theTop + spacer) total width accViewWidth label text "Mask prompt : " field left 0

set {MaskLabel, theTop} to create label "MASKING OPTIONS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type

set {theRule3, theTop} to create rule (theTop + spacer) rule width accViewWidth

set {denoise_Field, denoise_Label, unusedTop, fieldLeft} to create side labeled field denoise_level bottom (theTop + spacer + 2) total width accViewWidth / 3 - 10 label text "Denoise level :   " field left 0 left inset (accViewWidth / 3) * 2 + 10
set {seed_value_Field, seed_value_Label, unusedTop, fieldLeft} to create side labeled field seed_value bottom (theTop + spacer + 2) total width accViewWidth / 3 - 10 label text "Last seed :" field left 0 left inset accViewWidth / 3
set {seedControl_Popup, seedControl_Label, theTop} to create labeled popup seedTypeList bottom (theTop + spacer) popup width 120 max width accViewWidth / 3 - 10 label text "Seed control :" popup left 0 initial choice seed_control

set {negative_prompt_Field, negative_prompt_Label, unusedTop} to create top labeled field negative_prompt bottom (theTop + spacer) field width accViewWidth / 2 - 110 label text "Negative prompt : " left inset accViewWidth / 2 + 110 extra height 40 without accepts linebreak and tab
set {positive_prompt_Field, positive_prompt_Label, theTop} to create top labeled field positive_prompt bottom (theTop + spacer) field width accViewWidth / 2 + 100 label text "Positive prompt : " left inset 0 extra height 40 without accepts linebreak and tab
set {PromptLabel, theTop} to create label "PROMPTING PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type

set {theRule2, theTop} to create rule (theTop + spacer) rule width accViewWidth

set {theMatrixValue, unusedTop} to create matrix resolutionOptions left inset accViewWidth / 2 bottom (theTop + spacer) max width accViewWidth / 2 initial choice theResolution without arranged vertically
if InpaintON is true then
	set {InpaintCheckbox, unusedTop, newWidth} to create checkbox "INPAINT MODE" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset accViewWidth / 4 with initial state
else
	set {InpaintCheckbox, unusedTop, newWidth} to create checkbox "INPAINT MODE" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset accViewWidth / 4 without initial state
end if
if TurboON is true then
	set {TurboCheckbox, theTop, newWidth} to create checkbox "TURBO MODE" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset 0 with initial state
else
	set {TurboCheckbox, theTop, newWidth} to create checkbox "TURBO MODE" bottom (theTop + spacer) max width accViewWidth / 4 - 10 left inset 0 without initial state
end if
--
set {WorkflowList_Popup, WorkflowList_Label, unusedTop} to create labeled popup workflowList bottom (theTop + spacer) popup width accViewWidth / 3 - 10 max width accViewWidth / 3 label text "Workflow to use :" popup left accViewWidth - (accViewWidth / 3) + 8 initial choice workflow
log "server_url :" & server_url
set {server_url_Field, server_url_Label, theTop, fieldLeft} to create side labeled field server_url placeholder text "127.0.0.1:8188" bottom (theTop + spacer) total width accViewWidth / 2 - 10 label text "Server adress :" field left 0
set {ComfyUILabel, theTop} to create label "ComfyUI PARAMETERS" bottom theTop + spacer max width accViewWidth control size regular size aligns left aligned with bold type
set {theRule1, theTop} to create rule (theTop + spacer) rule width accViewWidth
set {boldLabel, theTop} to create label "-:| ComfyONE |:-" bottom theTop + 10 max width accViewWidth control size large size aligns right aligned with bold type

set allControls to {inpaintEnd_Field, inpaintEnd_Label, inpaintStart_Field, inpaintStart_Label, inpaintStrenght_Field, inpaintStrenght_Label, createdByLabel, theRule6, theRule7, ipAdapterInfoLabel, ipAdapter_strength_Field, ipAdapter_strength_Label, ipAdapterImgPath, ipAdapterImgPathLabel, ipAdapterCheckbox, IPAdapterLabel, theRule5, CtrNetInfoLabel, ctrlBImgPath, ctrlBImgPathLabel, ctrlAImgPath, ctrlAImgPathLabel, ctrlB_strength_Field, ctrlB_strength_Label, ctrlA_strength_Field, ctrlA_strength_Label, ctrlB_end_Field, ctrlB_end_Label, ctrlA_end_Field, ctrlA_end_Label, ctrlB_start_Field, ctrlB_start_Label, ctrlA_start_Field, ctrlA_start_Label, CtrlNetBCheckbox, CtrlNetACheckbox, CtrlNetBLabel, CtrlNetALabel, theRule4, fillMaskHoleCheckbox, contextExpandFactor_Field, contextExpandFactor_Label, contextExpandPixels_Field, contextExpandPixels_Label, invertMaskCheckbox, blendInpaint_Field, blendInpaint_Label, blurInpaint_Field, blurInpaint_Label, maskBlur_Field, maskBlur_Label, maskExpand_Field, maskExpand_Label, mask_prompt_Field, mask_prompt_Label, MaskLabel, theRule3, InpaintLabel, denoise_Field, denoise_Label, seed_value_Field, seed_value_Label, seedControl_Popup, seedControl_Label, negative_prompt_Field, negative_prompt_Label, positive_prompt_Field, positive_prompt_Label, PromptLabel, theRule2, theMatrixValue, InpaintCheckbox, TurboCheckbox, WorkflowList_Popup, WorkflowList_Label, server_url_Field, server_url_Label, ComfyUILabel, theRule1, boldLabel}
set {buttonName, controlsResults} to display enhanced window windowTitle acc view width accViewWidth acc view height theTop acc view controls allControls buttons theButtons with align cancel button

log controlsResults

--display dialog controlsResults as string

-- Récupération des valeurs en cas de clic sur "Generate" ou "Save"
if buttonName is "Generate" or buttonName is "SAVE" then
	try
		set server_url to item 76 of controlsResults
		set mask_prompt to item 54 of controlsResults
		set positive_prompt to item 67 of controlsResults
		set negative_prompt to item 65 of controlsResults
		set seed_value to item 61 of controlsResults
		set seed_control to item 63 of controlsResults
		set denoise_level to item 59 of controlsResults
		set ctrlA_strength to item 25 of controlsResults
		set ctrlA_start to item 33 of controlsResults
		set ctrlA_end to item 29 of controlsResults
		set ctrlB_strength to item 23 of controlsResults
		set ctrlB_start to item 31 of controlsResults
		set ctrlB_end to item 27 of controlsResults
		set fillMaskHole to item 40 of controlsResults
		set invertMask to item 45 of controlsResults
		set blurInpaint to item 48 of controlsResults
		set blendInpaint to item 46 of controlsResults
		set contextExpandPixels to item 43 of controlsResults
		set contextExpandFactor to item 41 of controlsResults
		set ipAdapter_strength to item 5 of controlsResults
		set workflow to item 74 of controlsResults
		set ipAdapterImg to item 13 of controlsResults
		set ctrlBImg to item 19 of controlsResults
		set ctrlAImg to item 21 of controlsResults
		set TurboON to item 73 of controlsResults
		set InpaintON to item 72 of controlsResults
		set ctrlAON to item 36 of controlsResults
		set ctrlBON to item 35 of controlsResults
		set ipAdapterON to item 15 of controlsResults
		set maskExpand to item 52 of controlsResults
		set maskBlur to item 50 of controlsResults
		set theResolution to item 71 of controlsResults
		set inpaintStrenght to item 5 of controlsResults
		set inpaintStart to item 3 of controlsResults
		set inpaintEnd to item 1 of controlsResults
		
	on error errMsg number errNum
		display dialog "Erreur lors de l'obtention des valeurs dans controlsResults : " & errMsg
	end try
	
	-- Enregistrement des valeurs dans le stockage si SAVE ou GENERATE
	assign value server_url to key "server_url"
	assign value mask_prompt to key "mask_prompt"
	assign value positive_prompt to key "positive_prompt"
	assign value negative_prompt to key "negative_prompt"
	assign value seed_value to key "seed_value"
	assign value seed_control to key "seed_control"
	assign value denoise_level to key "denoise_level"
	assign value ctrlA_strength to key "ctrlA_strength"
	assign value ctrlA_start to key "ctrlA_start"
	assign value ctrlA_end to key "ctrlA_end"
	assign value ctrlB_strength to key "ctrlB_strength"
	assign value ctrlB_start to key "ctrlB_start"
	assign value ctrlB_end to key "ctrlB_end"
	assign value fillMaskHole to key "fillMaskHole"
	assign value invertMask to key "invertMask"
	assign value blurInpaint to key "blurInpaint"
	assign value blendInpaint to key "blendInpaint"
	assign value contextExpandPixels to key "contextExpandPixels"
	assign value contextExpandFactor to key "contextExpandFactor"
	assign value ipAdapter_strength to key "ipAdapter_strength"
	assign value workflow to key "workflow"
	assign value ipAdapterImg to key "ipAdapterImg"
	assign value ctrlBImg to key "ctrlBImg"
	assign value ctrlAImg to key "ctrlAImg"
	assign value TurboON to key "TurboON"
	assign value InpaintON to key "InpaintON"
	assign value ctrlAON to key "ctrlAON"
	assign value ctrlBON to key "ctrlBON"
	assign value ipAdapterON to key "ipAdapterON"
	assign value theResolution to key "theResolution"
	assign value maskExpand to key "maskExpand"
	assign value maskBlur to key "maskBlur"
	assign value inpaintStrenght to key "inpaintStrenght"
	assign value inpaintStart to key "inpaintStart"
	assign value inpaintEnd to key "inpaintEnd"
	
	if buttonName is "Generate" then
		-- Définition du chemin et de la commande pour lancer le script
		
		try
			-- Récupérer le répertoire du script actuel
			set scriptDir to POSIX path of (path to me as text)
			set scriptDir to do shell script "dirname " & quoted form of scriptDir
			
			-- Construire le chemin vers le script "Generate.scptd"
			set scriptPath to scriptDir & "/Generate.scptd"
			log "scriptPath : " & scriptPath
			
			-- Charger et exécuter le script "Generate.scptd"
			set generateScript to load script (scriptPath as POSIX file as alias)
			run generateScript
			
		on error errMsg number errNum
			display dialog "Erreur lors de l'exécution du script : " & errMsg & " (Numéro : " & errNum & ")" buttons {"OK"} default button "OK"
		end try
		
	end if
	-- Si l'utilisateur appuie sur "Cancel", sortir du script sans afficher d'erreur
	if buttonName is "Cancel" then
		return
	end if
end if




