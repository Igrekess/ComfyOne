import json

def verify_json_structure(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        json_data = json.load(f)
    
    for node_id, node_content in json_data.items():
        if not isinstance(node_id, str):
            print(f"Erreur: node_id {node_id} n'est pas une chaîne.")
        if not isinstance(node_content, dict):
            print(f"Erreur: node_content pour node_id {node_id} n'est pas un dictionnaire.")
        elif '_meta' in node_content and not isinstance(node_content['_meta'], dict):
            print(f"Erreur: '_meta' pour node_id {node_id} n'est pas un dictionnaire.")
        elif '_meta' in node_content and 'title' in node_content['_meta'] and not isinstance(node_content['_meta']['title'], str):
            print(f"Erreur: 'title' dans '_meta' pour node_id {node_id} n'est pas une chaîne.")

# Remplacez '00_Base_Flux.json' par le chemin vers votre fichier JSON
verify_json_structure('/Users/yan/Library/Scripts/Capture One Scripts/DIT Toolkit/ComfyOne/workflows/00_Base_Flux.json')