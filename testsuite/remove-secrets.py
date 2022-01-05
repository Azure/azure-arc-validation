import json
import tarfile
import os
import sys
import enum

class FileType(enum.Enum):
    definition_json = 1
    core_v1_configmaps = 2
    core_v1_pods = 3


def import_and_fix_json(file, fileType):
    file_object = open(file,)
    data = json.load(file_object)
    file_object.close()

    # temporary logic until sonobuoy provides hiding secrets
    if fileType == FileType.definition_json:
        data = fix_definition_json(data)

    if fileType == FileType.core_v1_configmaps:
        data = fix_core_v1_configmaps(data)

    if fileType == FileType.core_v1_pods:
        data = fix_core_v1_pods(data)

    with open(file, 'w') as json_file:
        json.dump(data, json_file)


def fix_definition_json(data):
    index = 0
    for i in data["Definition"]["spec"]["env"]:
        key = i["name"].lower()
        if key is not None and "client_secret" in key:
            data["Definition"]["spec"]["env"][index]["value"] = ""
        index+=1
    
    return data


def sonobuoy_retrieve_and_fix(result_tar_file, folder):

    tar_file_object = tarfile.open(result_tar_file)
    tar_file_object.extractall(folder)
    tar_file_object.close()

    os.remove(result_tar_file)

    for root, dirnames, filenames in os.walk(folder):
        for item in filenames:
            # sometimes sonobuoy is making defintion.json instead of definition.json
            if item.endswith("defintion.json") or item.endswith("definition.json"):
                fileNamePath = str(os.path.join(root,item))
                import_and_fix_json(fileNamePath, FileType.definition_json)
            
            if item.endswith("core_v1_configmaps.json"):
                fileNamePath = str(os.path.join(root,item))
                if "sonobuoy" in fileNamePath:
                    import_and_fix_json(fileNamePath, FileType.core_v1_configmaps)

            if item.endswith("core_v1_pods.json"):
                fileNamePath = str(os.path.join(root,item))
                if "sonobuoy" in fileNamePath:
                    import_and_fix_json(fileNamePath, FileType.core_v1_pods)

    make_tarfile(result_tar_file, folder)


def make_tarfile(output_filename, source_dir):
    with tarfile.open(output_filename, "w:gz") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))   


def fix_core_v1_configmaps(data):
    for item in data["items"]:
        if item["metadata"]["name"] == "sonobuoy-plugins-cm":
            data = item["data"]
            for key, value in data.items():
                plugin_config_str = value
                data[key] = fix_string(plugin_config_str)
    
    return data


def fix_string(str):
    secret_index = str.index("CLIENT_SECRET")
    value_index = str.index("value", secret_index + 6)
    secret_value_index = str.index(" ", value_index + 7)

    return str[:value_index + 7] + str[secret_value_index:]


def fix_core_v1_pods(data):
    outer_index = 0
    for item in data["items"]:
        container_index = 0
        for container in item["spec"]["containers"]:
            index = 0
            for env in container["env"]:
                if "client_secret" in env["name"].lower():
                    data["items"][outer_index]["spec"]["containers"][container_index]["env"][index]["value"] = ""
                index+=1
            container_index+=1
        outer_index+=1

    return data


sonobuoy_retrieve_and_fix(sys.argv[1], sys.argv[2])