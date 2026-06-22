import pandas as pd
import json

def convert_excel_to_json(excel_path, json_path):
    df = pd.read_excel(excel_path, dtype=str, keep_default_na=False)
    df = df.fillna("")

    if 'id' not in df.columns:
        raise ValueError("Excel中缺少'id'列")

    nodes = {}
 # 从第二行开始遍历
    for _, row in df.iloc[1:].iterrows():
        node_id = row['id']
        if not node_id:
            continue

        node = {}
        for col in df.columns:
            cell_val = row[col]
            # 核心：尝试解析 JSON 格式字符串（数组/对象）
            if cell_val.startswith(("[", "{")) and cell_val.endswith(("]", "}")):
                try:
                    # 字符串转成真实数组/字典
                    parsed_val = json.loads(cell_val)
                    node[col] = parsed_val
                except json.JSONDecodeError:
                    # 解析失败，保留原字符串
                    node[col] = cell_val
            else:
                # 普通文本直接赋值
                node[col] = cell_val

        nodes[node_id] = node

    dialogue_data = nodes
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dialogue_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    convert_excel_to_json("excel/dialogue.xlsx", "excel/dialogue.json")