import io
import json
import logging
import requests
import sys
import urllib.parse
import urllib.request
import uuid
import websocket
from pathlib import Path
from PIL import Image
from datetime import datetime
import subprocess
import platform
import os

# Configuration du dossier de log
script_dir = Path(__file__).resolve().parent
log_dir = script_dir / "log"
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / "comfyOne_log.txt"

# Configuration des logs pour enregistrer dans le fichier log_file
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
# Génération d'un ID unique pour le client
client_id = str(uuid.uuid4())

# Récupération des arguments depuis sys.argv
(
    server_url, positive_prompt, negative_prompt, seed_value, denoise_value, img_path, selected_workflow,
    ctrl_a_on, ctrl_b_on, ip_adapter_on, fill_mask_hole, mask_prompt, mask_blur, mask_expand, invert_mask,
    blur_inpaint, blend_inpaint, context_expand_pixels, context_expand_factor, ctrl_a_start, ctrl_a_end,
    ctrl_a_strength, ctrl_b_start, ctrl_b_end, ctrl_b_strength, ip_adapter_strength, turbo_on, inpaint_on, mask_fill, raw_src_path, ip_adapter_img,
    ctrl_a_img, ctrl_b_img, the_resolution, inpaintStrenght, inpaintStart, inpaintEnd
) = sys.argv[1:]

# Convertir certains arguments en types appropriés
seed_value = int(seed_value)
denoise_value = float(denoise_value)
ctrl_a_on = ctrl_a_on.lower() == 'true'
ctrl_b_on = ctrl_b_on.lower() == 'true'
ip_adapter_on = ip_adapter_on.lower() == 'true'
fill_mask_hole = fill_mask_hole.lower() == 'true'
invert_mask = invert_mask.lower() == 'true'
turbo_on = turbo_on.lower() == 'true'
inpaint_on = inpaint_on.lower() == 'true'
mask_expand = int(mask_expand)
mask_blur = float(mask_blur)
blur_inpaint = float(blur_inpaint)
blend_inpaint = float(blend_inpaint)
context_expand_pixels = int(context_expand_pixels)
context_expand_factor= float(context_expand_factor)
ctrl_a_start = float(ctrl_a_start)
ctrl_a_end =float(ctrl_a_end)
ctrl_a_strength = float(ctrl_a_strength)
ctrl_b_start = float(ctrl_b_start)
ctrl_b_end = float(ctrl_b_end)
ctrl_b_strength = float(ctrl_b_strength)
ip_adapter_strength = float(ip_adapter_strength)
inpaintStrenght = float(inpaintStrenght)
inpaintStart = float(inpaintStart)
inpaintEnd = float(inpaintEnd)

# Vérification de l'existence de l'image source
if not Path(img_path).exists():
    logging.error(f"Erreur : Le fichier image source '{img_path}' est introuvable.")
    sys.exit(1)

# Log des paramètres récupérés
logging.info(f"-----------------------------------")
logging.info(f"Date : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
logging.info(f"-----------------------------------")
logging.info(f"Server URL: {server_url}")
logging.info(f"Seed Value: {seed_value}")
logging.info(f"Positive Prompt: {positive_prompt}")
logging.info(f"Negative Prompt: {negative_prompt}")
logging.info(f"Denoise Value: {denoise_value}")
logging.info(f"Image Path: {img_path}")
logging.info(f"Workflow: {selected_workflow}")
logging.info(f"Control A ON: {ctrl_a_on}")
logging.info(f"Control B ON: {ctrl_b_on}")
logging.info(f"IP Adapter ON: {ip_adapter_on}")
logging.info(f"Fill Mask Hole: {fill_mask_hole}")
logging.info(f"Mask Prompt: {mask_prompt}")
logging.info(f"Mask Blur: {mask_blur}")
logging.info(f"Mask Expand: {mask_expand}")
logging.info(f"Invert Mask: {invert_mask}")
logging.info(f"Blur Inpaint: {blur_inpaint}")
logging.info(f"Blend Inpaint: {blend_inpaint}")
logging.info(f"Context Expand Pixels: {context_expand_pixels}")
logging.info(f"Context Expand Factor: {context_expand_factor}")
logging.info(f"Control A Start: {ctrl_a_start}")
logging.info(f"Control A End: {ctrl_a_end}")
logging.info(f"Control A Strength: {ctrl_a_strength}")
logging.info(f"Control B Start: {ctrl_b_start}")
logging.info(f"Control B End: {ctrl_b_end}")
logging.info(f"Control B Strength: {ctrl_b_strength}")
logging.info(f"IP Adapter Strength: {ip_adapter_strength}")
logging.info(f"Turbo ON: {turbo_on}")
logging.info(f"Inpaint ON: {inpaint_on}")
logging.info(f"Mask Fill: {mask_fill}")
logging.info(f"Raw Source Path: {raw_src_path}")
logging.info(f"IP Adapter Image: {ip_adapter_img}")
logging.info(f"Control A Image: {ctrl_a_img}")
logging.info(f"Control B Image: {ctrl_b_img}")
logging.info(f"Resolution: {the_resolution}")
logging.info(f"Inpaint ControlNet Strenght: {inpaintStrenght}")
logging.info(f"Inpaint ControlNet Start: {inpaintStart}")
logging.info(f"Inpaint ControlNet End: {inpaintEnd}")

# Fonction pour charger le JSON et identifier les nœuds par leur titre unique
def load_json(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def find_node_by_title(json_data, target_title):
    for node_id, node_content in json_data.items():
        if '_meta' in node_content and node_content['_meta'].get('title') == target_title:
            return node_id
    return None

# Fonction pour mettre en file d'attente un prompt
def queue_prompt(prompt):
    p = {"prompt": prompt, "client_id": client_id}
    data = json.dumps(p).encode('utf-8')
    req = urllib.request.Request(f"http://{server_url}/prompt", data=data)
    return json.loads(urllib.request.urlopen(req).read())

# Fonction pour obtenir une image depuis le serveur
def get_image(filename, subfolder, folder_type):
    data = {"filename": filename, "subfolder": subfolder, "type": folder_type}
    url_values = urllib.parse.urlencode(data)
    with urllib.request.urlopen(f"http://{server_url}/view?{url_values}") as response:
        return response.read()

# Fonction pour obtenir l'historique d'un prompt
def get_history(prompt_id):
    with urllib.request.urlopen(f"http://{server_url}/history/{prompt_id}") as response:
        return json.loads(response.read())

# Fonction pour obtenir les images générées en filtrant sur le node_id qui nous intéresse
def get_images(ws, prompt):
    prompt_id = queue_prompt(prompt)['prompt_id']
    output_images = {}

    while True:
        out = ws.recv()
        if isinstance(out, str):
            message = json.loads(out)
            if message['type'] == 'executing':
                data = message['data']
                if data['node'] is None and data['prompt_id'] == prompt_id:
                    break
            elif message['type'] == 'progress':
                data = message['data']
                progress_msg = f"Progress: Step {data['value']} of {data['max']})"
                #print(progress_msg)  # Affichage console
                logging.info(progress_msg)  # Enregistrement dans les logs
        else:
            continue

    history = get_history(prompt_id)[prompt_id]
    node_id = node_ids["Save_image"]
    if node_id in history['outputs'] and 'images' in history['outputs'][node_id]:
        images_output = []
        for image in history['outputs'][node_id]['images']:
            image_data = get_image(image['filename'], image['subfolder'], image['type'])
            images_output.append(image_data)
        output_images[node_id] = images_output

    return output_images

# Fonction de téléchargement de fichier
def upload_file(file, subfolder="", overwrite=False):
    try:
        body = {"image": file}
        data = {"overwrite": "true"} if overwrite else {}
        if subfolder:
            data["subfolder"] = subfolder

        resp = requests.post(f"http://{server_url}/upload/image", files=body, data=data)
        resp.raise_for_status()
        resp_data = resp.json()
        path = resp_data["name"]
        if "subfolder" in resp_data and resp_data["subfolder"]:
            path = f"{resp_data['subfolder']}/{path}"
        return path
    except requests.exceptions.RequestException as error:
        logging.error(f"Erreur lors du téléchargement de l'image : {error}")
        return None


def save_generated_images(images, raw_src_path, seed_value, img_path):
    original_name = Path(img_path).stem
    save_node_id = node_ids.get("Save_image")
    if save_node_id and str(save_node_id) in images:
        for i, image_data in enumerate(images[str(save_node_id)]):
            image = Image.open(io.BytesIO(image_data))
            image_path = Path(raw_src_path) / f"{original_name}_INF_{seed_value}.png"
            image.save(image_path)
            logging.info(f"Image enregistrée : {image_path}")
    else:
        logging.error("Aucune image trouvée pour le nœud Save_image.")



# Upload de l'image source sur le serveur
with open(img_path, "rb") as f:
    comfyui_path_image = upload_file(f, "", True)

# Chargement du fichier JSON et recherche des nœuds par titre
json_path = script_dir / "workflows" / f"{selected_workflow}.json"
workflow_data = load_json(json_path)

# Titres des nœuds pour lesquels nous voulons identifier les identifiants
titles_to_find = {
    "Positive_prompt": "PositivePromptAPI",
    "Negative_prompt": "NegativePromptAPI",
    "MaskPromptAPI" : "MaskPromptAPI",
    "Seed": "SeedAPI",
    "Denoise": "DenoiseAPI",
    "Src_image": "SrcImgAPI",
    "Save_image": "SaveImgAPI",
    "CtrlNetA" : "CtrlNetAAPI",
    "CtrlNetB" : "CtrlNetBAPI",
    "UploadImgCtrlNetA" : "UploadImgCtrlNetA",
    "UploadImgCtrlNetB" : "UploadImgCtrlNetB",
    "IpAdapterAPI" :"IpAdapterAPI",
    "UploadImgipAdapter" : "UploadImgipAdapter",
    "MaskAPI" : "MaskAPI",
    "InpaintAPI" : "InpaintAPI",
    "InpaintOnAPI" : "InpaintOnAPI",
    "TurboOnAPI" : "TurboOnAPI",
    "ResolutionAPI" : "ResolutionAPI",
    "CtrlNetAOnAPI" : "CtrlNetAOnAPI",
    "CtrlNetBOnAPI" : "CtrlNetBOnAPI",
    "IpAdapterOnAPI" : "IpAdapterOnAPI",
    "InpaintControlAPI": "InpaintControlAPI"

}
node_ids = {key: find_node_by_title(workflow_data, title) for key, title in titles_to_find.items()}

# Log des node_ids trouvés
logging.info("Node IDs trouvés pour chaque titre :")
for key, node_id in node_ids.items():
    if node_id:
        logging.info(f"{titles_to_find[key]}: Node ID = {node_id}")
    else:
        logging.warning(f"{titles_to_find[key]}: Aucun node trouvé")

# Modifier les valeurs des nœuds trouvés en utilisant les numéros de nœuds
if node_ids["Positive_prompt"]:
    workflow_data[node_ids["Positive_prompt"]]["inputs"]["text"] = positive_prompt
if node_ids["Negative_prompt"]:
    workflow_data[node_ids["Negative_prompt"]]["inputs"]["text"] = negative_prompt
if node_ids["MaskPromptAPI"]:
    workflow_data[node_ids["MaskPromptAPI"]]["inputs"]["text"] = mask_prompt
if node_ids["Seed"]:
    workflow_data[node_ids["Seed"]]["inputs"]["seed"] = seed_value
if node_ids["Denoise"]:
    workflow_data[node_ids["Denoise"]]["inputs"]["value"] = denoise_value
if node_ids["Src_image"]:
    workflow_data[node_ids["Src_image"]]["inputs"]["image"] = comfyui_path_image
if node_ids["Save_image"]:
    workflow_data[node_ids["Save_image"]]["inputs"]["filename_prefix"] = f"{Path(img_path).stem}_INF"
if node_ids["MaskAPI"] :
    workflow_data[node_ids["MaskAPI"]]["inputs"]["expand"] = mask_expand
    workflow_data[node_ids["MaskAPI"]]["inputs"]["blur_radius"] = mask_blur
    workflow_data[node_ids["MaskAPI"]]["inputs"]["fill_holes"] = fill_mask_hole
    workflow_data[node_ids["MaskAPI"]]["inputs"]["flip_input"] = invert_mask
if node_ids["InpaintAPI"] :
    workflow_data[node_ids["InpaintAPI"]]["inputs"]["context_expand_pixels"] = context_expand_pixels
    workflow_data[node_ids["InpaintAPI"]]["inputs"]["context_expand_factor"] = context_expand_factor
if node_ids["CtrlNetAOnAPI"]:
    workflow_data[node_ids["CtrlNetAOnAPI"]]["inputs"]["value"] = ctrl_a_on
if node_ids["InpaintControlAPI"] :
    workflow_data[node_ids["InpaintControlAPI"]]["inputs"]["strength"] = inpaintStrenght
    workflow_data[node_ids["InpaintControlAPI"]]["inputs"]["start_percent"] = inpaintStart
    workflow_data[node_ids["InpaintControlAPI"]]["inputs"]["end_percent"] = inpaintEnd
if node_ids["CtrlNetA"] :
    workflow_data[node_ids["CtrlNetA"]]["inputs"]["strength"] = ctrl_a_strength
    workflow_data[node_ids["CtrlNetA"]]["inputs"]["start_percent"] = ctrl_a_start
    workflow_data[node_ids["CtrlNetA"]]["inputs"]["end_percent"] = ctrl_a_end
if node_ids["CtrlNetBOnAPI"] :
    workflow_data[node_ids["CtrlNetBOnAPI"]]["inputs"]["value"] = ctrl_b_on
if node_ids["CtrlNetB"] :
    workflow_data[node_ids["CtrlNetB"]]["inputs"]["strength"] = ctrl_b_strength
    workflow_data[node_ids["CtrlNetB"]]["inputs"]["start_percent"] = ctrl_b_start
    workflow_data[node_ids["CtrlNetB"]]["inputs"]["end_percent"] = ctrl_b_end
if node_ids["TurboOnAPI"] :
    workflow_data[node_ids["TurboOnAPI"]]["inputs"]["value"] = turbo_on
if node_ids["InpaintOnAPI"] :
    workflow_data[node_ids["InpaintOnAPI"]]["inputs"]["value"] = inpaint_on
if node_ids["IpAdapterOnAPI"] :
    workflow_data[node_ids["IpAdapterOnAPI"]]["inputs"]["value"] = ip_adapter_on
if node_ids["IpAdapterAPI"] :
    workflow_data[node_ids["IpAdapterAPI"]]["inputs"]["value"] = ip_adapter_strength
#if node_ids["SrcIpAdapterAPI"]:
#    workflow_data[node_ids["SrcIpAdapterAPI"]]["inputs"]["image"] = ip_adapter_img

# Connexion WebSocket et obtention des images
try:
    ws = websocket.WebSocket()
    ws.connect(f"ws://{server_url}/ws?clientId={client_id}")
    images = get_images(ws, workflow_data)
    save_generated_images(images, raw_src_path, seed_value, img_path)
    logging.info("Génération terminée : Les images générées ont été sauvegardées avec succès.")
    
    # Fermer le terminal après la sauvegarde
    #time.sleep(0.5)  # Délai de 500ms
    if platform.system() == 'Darwin':  # macOS
        subprocess.run(['osascript', '-e', 'tell application "Terminal" to close (every window whose name contains "generate.sh")'])
    elif platform.system() == 'Windows':
        subprocess.run(['taskkill', '/F', '/IM', 'cmd.exe'])
    else:  # Linux
        subprocess.run(['kill', str(os.getppid())])

except websocket.WebSocketException as e:
    logging.error(f"Erreur de connexion WebSocket : {e}")
    sys.exit(1)


