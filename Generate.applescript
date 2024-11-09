--···············································································································
-- ComfyONE - GENERATE
-- Author        : Yan Senez
-- Created on: 01/11/2024
-- Task          : Automate the interaction between Capture One and ComfyUI to get generative images with advanced diffusion methods.
-- Version       : 1.0
-- Copyright © 2024 Yan Senez, All Rights Reserved
--···············································································································

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "PrefsStorageLib" version "1.1.0" -- pour récupérer les préférences stockées
use framework "Foundation" -- pour JSON et WebSocket
prepare storage for domain "com.yse.comfyONE"

-- Debug line
--display dialog "Le script generate a été appelé avec succès." buttons {"OK"} default button "OK"





-- Préparation pour la génération des variantes via Capture One
on GenerateVariantUsingComfyUI()
	-- Chargement des préférences nécessaires
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
	
	tell application "Capture One" -- Capture One part -- We process the selected variant(s) with the "LAYOUT" recipe 
		tell front document
			try
				set LayoutRecipe to recipe "ComfyONE"
			on error
				set LayoutRecipe to make new recipe with properties {name:"ComfyONE", output format:JPEG_QuickProof, color profile:"sRGB Color Space Profile", export crop method:respect, ignore crop:false, include Camera Metadata:true, include copyright:true, root folder type:output location, output sub folder:"INFERENCE_PNG", sharpening:for screen, sharpening amount:60.0, sharpening distance:100.0, sharpening distance type:percent of diagonal, sharpening radius:0.600000023842, sharpening threshold:0.0, thumbnails:false}
				--tell LayoutRecipe to set {its enabled, its scaling method, its scaling unit, its primary scaling value} to {false, Long_Edge, pixels, 1344}
				tell LayoutRecipe to set {its enabled} to {false}
			end try
			set outputFormatValue to output format of LayoutRecipe
			set imgFolder to output sub folder of LayoutRecipe
			if outputFormatValue = JPEG_QuickProof then
				set fileExt to ".jpg"
			else if outputFormatValue = JPEG then
				set fileExt to ".jpg"
			else if outputFormatValue = TIFF then
				set fileExt to ".tif"
			else if outputFormatValue = PSD then
				set fileExt to ".psd"
			else if outputFormatValue = DNG then
				set fileExt to ".dng"
			else if outputFormatValue = PNG then
				set fileExt to ".png"
			end if
			set outputFolder to output
			set sessionPath to folder
		end tell
		set selectedVariants to (get selected variants)
		if selectedVariants is {} then -- if there is no variant selected, ask to choose one
			display dialog "Please, select an image and try again..."
		else
			repeat with thisVariant in selectedVariants
				process thisVariant recipe "Inference"
				repeat while thisVariant's queued is true
					delay 0.2
				end repeat
				log "-> outputFolder : " & outputFolder
				log "-> imgFolder : " & imgFolder
				set imgPath to (outputFolder & imgFolder & ":" & name of thisVariant & fileExt) as string -- we get the full path for the jpeg
				set rawSrcPath to path of parent image of thisVariant
				set rawSrcPath to do shell script "dirname " & quoted form of rawSrcPath
				--set imgSrc to "/Volumes" & imgSrc
				log "-> rawSrcPath ???? : " & rawSrcPath
				--log "!!!!!imgPath :" & imgPath
				set imgPath to my getIMGPath(outputFolder, imgFolder, name of thisVariant, fileExt)
				log "/////imgPath :" & imgPath
				set imgPathPosix to my convertToPosixPath(imgPath) -- conversion au format POSIX
				set imgPathPosix to "/Volumes" & imgPathPosix
				log "!!!!!imgPathPosix :" & imgPathPosix
				if seed_control is "Fixe" then
					set seed_value to seed_value
					assign value seed_value to key "seed_value"
				else if seed_control is "Increment" then
					set seed_value to seed_value + 1
					assign value seed_value to key "seed_value"
				else if seed_control is "Decrement" then
					set seed_value to seed_value - 1
					assign value seed_value to key "seed_value"
				else if seed_control is "Random" then
					set seed_value to (random number from 1 to 100000000) as integer
					assign value seed_value to key "seed_value"
				end if
				log "SEED : " & seed_value
				-- Créer le fichier d'arguments pour le script
				try
					set argsFile to "/tmp/comfyOne_args.txt"
					set argsContent to "\"" & server_url & "\" \"" & positive_prompt & "\" \"" & negative_prompt & "\" \"" & seed_value & "\" \"" & denoise_level & "\" \"" & imgPathPosix & "\" \"" & workflow & "\" \"" & ctrlAON & "\" \"" & ctrlBON & "\" \"" & ipAdapterON & "\" \"" & fillMaskHole & "\" \"" & mask_prompt & "\" \"" & maskBlur & "\" \"" & maskExpand & "\" \"" & invertMask & "\" \"" & blurInpaint & "\" \"" & blendInpaint & "\" \"" & contextExpandPixels & "\" \"" & contextExpandFactor & "\" \"" & ctrlA_start & "\" \"" & ctrlA_end & "\" \"" & ctrlA_strength & "\" \"" & ctrlB_start & "\" \"" & ctrlB_end & "\" \"" & ctrlB_strength & "\" \"" & ipAdapter_strength & "\" \"" & TurboON & "\" \"" & InpaintON & "\" \"" & maskFill & "\" \"" & rawSrcPath & "\" \"" & ipAdapterImg & "\" \"" & ctrlAImg & "\" \"" & ctrlBImg & "\" \"" & theResolution & "\" \"" & inpaintStrenght & "\" \"" & inpaintStart & "\" \"" & inpaintEnd & "\""
					
					do shell script "echo " & quoted form of argsContent & " > " & argsFile
					
					-- Vérifier si le fichier a été créé
					set argsFileExists to (do shell script "test -f " & argsFile & " && echo exists") as text
					if argsFileExists is not "exists" then
						display dialog "Erreur : le fichier temporaire des arguments n'a pas été créé." buttons {"OK"} default button "OK"
						return
					end if
					
					-- Démarrer la tâche avec launchctl pour liberer capture one
					do shell script "launchctl start com.yse.comfyONE"
					
				on error errMsg number errNum
					display dialog "Erreur lors de la création du fichier d'arguments ou de l'exécution du script : " & errMsg & " (Numéro : " & errNum & ")" buttons {"OK"} default button "OK"
				end try
			end repeat
		end if
	end tell
end GenerateVariantUsingComfyUI

-- Fonction pour obtenir le chemin complet de l'image
on getIMGPath(outputFolder, imgFolder, outputName, fileExt)
	tell application "Finder"
		set imgPath to (outputFolder & imgFolder & ":" & outputName & fileExt) as string
		if exists file imgPath then
			set n to 1
			repeat
				set newImgPath to (outputFolder & imgFolder & ":" & outputName & " " & n & fileExt) as string
				if not (exists file newImgPath) then exit repeat
				set n to n + 1
			end repeat
			if n = 1 then
				set imgPath to (outputFolder & imgFolder & ":" & outputName & fileExt) as string
			else
				set imgPath to (outputFolder & imgFolder & ":" & outputName & " " & n - 1 & fileExt)
			end if
		end if
	end tell
	log "imgPath return :" & imgPath
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to ","
	set imgPathList to text items of imgPath
	set AppleScript's text item delimiters to ""
	set imgPath to imgPathList as string
	set AppleScript's text item delimiters to oldDelims
	log "*************** imgPath in function :" & imgPath
	return imgPath
end getIMGPath

-- Fonction pour ajouter des paramètres optionnels à la commande
on appendCommandParameter(command, condition, parameterFlag, strengthFlag, strengthValue, startFlag, startValue, endFlag, endValue, optionalImg)
	if condition then
		set command to command & " " & parameterFlag
		if strengthFlag is not equal to "" then
			set command to command & " " & strengthFlag & " " & strengthValue
		end if
		if startFlag is not equal to "" then
			set command to command & " " & startFlag & " " & startValue
		end if
		if endFlag is not equal to "" then
			set command to command & " " & endFlag & " " & endValue
		end if
		if optionalImg is not missing value then
			set command to command & " " & optionalImg
		end if
	end if
	return command
end appendCommandParameter

on convertToPosixPath(macPath)
	set macPath to macPath as text
	set AppleScript's text item delimiters to ":"
	set pathParts to text items of macPath
	set AppleScript's text item delimiters to "/"
	set posixPath to pathParts as string
	set AppleScript's text item delimiters to ""
	return "/" & posixPath
end convertToPosixPath


-- Appeler la fonction principale
GenerateVariantUsingComfyUI()
