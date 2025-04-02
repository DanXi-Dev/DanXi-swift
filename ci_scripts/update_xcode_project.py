import json
import os
import subprocess

# check condition
if os.environ.get('CI_PRODUCT_PLATFORM') != 'iOS':
    # macOS: Replace "校园助手" with "旦挞" in iOS/InfoPlist.xcstrings
    base_path = os.environ.get('CI_PROJECT_FILE_PATH')
    file_path = os.path.join(base_path, 'iOS/InfoPlist.xcstrings')
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        updated_content = content.replace("校园助手", "旦挞")
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(updated_content)
    exit(0)

# iOS

# read file and convert to json
file = os.environ.get('XCODE_PROJ_FILE')
original_json_string = subprocess.run(['plutil', '-convert', 'json', file, '-o', '-'], capture_output=True)
xcode_object = json.loads(original_json_string.stdout)

# insert the value object after the key
insertion_map = {
    '27C6B47A2C2B3895006841C7': {
        "27ACD4522D88A665000EE8B5": {
            "isa": "PBXContainerItemProxy",
            "containerPortal": "8AC7A5C526872C3E00C9CD98",
            "remoteGlobalIDString": "274C196F29D1BF9B000DE221",
            "remoteInfo": "DanXi Watch",
            "proxyType": "1"
        },
        "27ACD4532D88A665000EE8B5": {
            "isa": "PBXTargetDependency",
            "platformFilter": "ios",
            "target": "274C196F29D1BF9B000DE221",
            "targetProxy": "27ACD4522D88A665000EE8B5"
        }
    },
    '8AC7A5C526872C3E00C9CD98': {
        "27ACD4552D88A66B000EE8B5": {
            "isa": "PBXContainerItemProxy",
            "containerPortal": "8AC7A5C526872C3E00C9CD98",
            "remoteGlobalIDString": "274C196F29D1BF9B000DE221",
            "remoteInfo": "DanXi Watch",
            "proxyType": "1"
        },
        "27ACD4562D88A66B000EE8B5": {
            "isa": "PBXTargetDependency",
            "target": "274C196F29D1BF9B000DE221",
            "targetProxy": "27ACD4552D88A66B000EE8B5"
        },
    },
    '8AC7A5C426872C3E00C9CD98': {
        "27ACD4542D88A66B000EE8B5": {
            "isa": "PBXBuildFile",
            "settings": {
                "ATTRIBUTES": [
                    "RemoveHeadersOnCopy"
                ]
            },
            "platformFilter": "ios",
            "fileRef": "274C197029D1BF9B000DE221"
        }
    }
}

# replace the field in the value with `updated` paired with the key
replacing_map = {
    '8AC7A5CC26872C3E00C9CD98': {
        'key': "dependencies",
        'updated': [
            "27ACD4532D88A665000EE8B5",
            "27D3A49A2BBC9D5300350D21",
            "27ACD4562D88A66B000EE8B5"
        ]
    },
    '8AC7A63326872C4100C9CD98': {
        'key': "files",
        'updated': ["27ACD4542D88A66B000EE8B5"]
    }
}

# update the json object
prev_objects = xcode_object['objects']
new_objects = {}

for key, value in prev_objects.items():
    # check for replacement
    if key in replacing_map:
        replacing_info = replacing_map[key]
        value[replacing_info['key']] = replacing_info['updated']

    new_objects[key] = value

    # check for insertion
    if key in insertion_map:
        inserted_map = insertion_map[key]
        for k, v in inserted_map.items():
            new_objects[k] = v

xcode_object['objects'] = new_objects

# write the json back to the file
with open(file, 'w') as w:
    json_string = json.dumps(xcode_object)
    w.write(json_string)
