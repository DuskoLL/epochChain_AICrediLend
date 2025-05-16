import requests
import csv
from datetime import datetime
from decimal import Decimal
import time
import os  # 新增导入os模块

# 配置参数
contract_address = '0x514910771af9ca656af840dff83e8264ecf986ca'  # 代币合约地址
api_key = 'RHA5C894SEDNX4H1P9RI2H9452INXM9DM6'  # 替换为你的API密钥
output_filename = 'LINK.csv'  # 输出文件名

# API基础URL和参数
base_url = 'https://api.etherscan.io/api'
params = {
    'module': 'account',
    'action': 'tokentx',
    'contractaddress': contract_address,
    'startblock': 0,
    'endblock': 9999999999,  # 默认最大区块号
    'sort': 'asc',
    'apikey': api_key,
    'page': 1,
    'offset': 100,  # 每次请求最大100条
}

all_transactions = []
page = 1

print("开始获取代币合约交易数据...")
while True:
    params['page'] = page

    try:
        response = requests.get(base_url, params=params)
        response.raise_for_status()

        data = response.json()
        if data['status'] != '1':
            print(f"API返回错误：{data.get('message', '未知错误')}")
            if data['message'] == 'No transactions found':
                print("没有找到交易记录")
            break

        transactions = data['result']
        if not transactions:
            print("数据已全部获取完毕")
            break

        all_transactions.extend(transactions)
        print(f"已获取第 {page} 页，{len(transactions)} 条记录")

        # 检查是否最后一页
        if len(transactions) < params['offset']:
            break

        page += 1
        time.sleep(0.5)  # 降低请求频率

    except requests.exceptions.HTTPError as e:
        print(f"HTTP错误: {e.response.status_code}")
        break
    except Exception as e:
        print(f"发生错误：{str(e)}")
        break

print(f"共获取到 {len(all_transactions)} 条交易记录")

# 写入CSV文件
csv_fields = [
    'block_number', 'transaction_hash', 'from_address', 'to_address',
    'value', 'timestamp', 'token_symbol', 'token_address', 'datetime'
]

# 检查文件是否存在及是否为空
file_exists = os.path.isfile(output_filename)
file_empty = False
if file_exists:
    file_empty = os.path.getsize(output_filename) == 0

# 根据文件存在情况选择模式，并处理表头
with open(output_filename, 'a' if file_exists else 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=csv_fields)
    # 如果文件不存在或为空，写入表头
    if not file_exists or file_empty:
        writer.writeheader()

    for tx in all_transactions:
        try:
            # 精度转换处理
            value = Decimal(tx['value']) / (10 ** int(tx['tokenDecimal']))

            # 时间戳转换
            dt = datetime.utcfromtimestamp(int(tx['timeStamp']))

            writer.writerow({
                'block_number': tx['blockNumber'],
                'transaction_hash': tx['hash'],
                'from_address': tx['from'],
                'to_address': tx['to'],
                'value': str(value.normalize()),  # 科学计数法转普通格式
                'timestamp': tx['timeStamp'],
                'token_symbol': tx['tokenSymbol'],
                'token_address': tx['contractAddress'],
                'datetime': dt.strftime('%Y-%m-%d %H:%M:%S')
            })

        except Exception as e:
            print(f"处理交易 {tx.get('hash', '未知')} 时出错: {str(e)}")

print(f"数据已保存至 {output_filename}")

# 可选：添加数据统计
print("\n数据统计：")
print(f"最早交易时间：{all_transactions[0]['timeStamp'] if all_transactions else '无'}")
print(f"最新交易时间：{all_transactions[-1]['timeStamp'] if all_transactions else '无'}")
print(f"总交易量：{sum(Decimal(tx['value']) / (10 ** int(tx['tokenDecimal'])) for tx in all_transactions)}")