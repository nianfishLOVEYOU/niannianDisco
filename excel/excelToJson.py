import pandas as pd
import json
import ast

def safe_eval_json(val):
    """将Excel中的字符串转为Python对象（list/dict）"""
    if pd.isna(val) or val == "":
        return None
    try:
        return ast.literal_eval(val)
    except:
        return val

def convert_excel_to_json(excel_path, json_path):
    df = pd.read_excel(excel_path, dtype=str).fillna("")
    nodes = {}
    start_node = None
    for _, row in df.iterrows():
        node_id = row['id']
        if node_id == "start_node":
            start_node = row.get('value')  # 特殊行记录开始节点
            continue
        node = {}
        if row.get('speaker'): node['speaker'] = row['speaker']
        if row.get('text'): node['text'] = row['text']
        if row.get('text_variants'): node['text_variants'] = safe_eval_json(row['text_variants'])
        if row.get('options'): node['options'] = safe_eval_json(row['options'])
        if row.get('random_next'): node['random_next'] = safe_eval_json(row['random_next'])
        if row.get('next'): node['next'] = row['next']
        if row.get('effects'): node['effects'] = safe_eval_json(row['effects'])
        nodes[node_id] = node
    dialogue_data = {"start_node": start_node, "nodes": nodes}
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dialogue_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    convert_excel_to_json("excel/dialogue.xlsx", "excel/dialogue.json")