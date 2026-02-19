print("############ Running DeepLabCut ############\n")
import deeplabcut
print("Options and paths")
path_config = '/mnt/MD1200B/egarza/jrasgado/Alcohol_model/Behavior/DLC_tracking/All_Groups/EPM-Jalil-2022-03-18/config.yaml'
print(f"path config: {path_config} \n")

print("Training network\n")
deeplabcut.train_network(path_config)

print("Evaluate network\n")
deeplabcut.evaluate_network(path_config)
