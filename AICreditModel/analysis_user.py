# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler

# --------------------------
# 训练模型并保存（只需运行一次）
# --------------------------
def train_and_save_model():
    # 加载数据
    df = pd.read_csv('dataset_mylabels_2020.csv')
    df['labels'] = np.where(df['labels'] == 'No label', 0, 1)
    
    # 定义特征
    features = [
        'balance_ether', 
        'total_transactions', 
        'sent', 
        'received',
        'n_contracts_sent', 
        'n_contracts_received'
    ]
    
    # 预处理
    X = df[features].fillna(df[features].median())
    y = df['labels']
    
    # 标准化
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # 处理类别不平衡
    from imblearn.over_sampling import SMOTE
    smote = SMOTE(random_state=42)
    X_resampled, y_resampled = smote.fit_resample(X_scaled, y)
    
    # 训练模型
    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=12,
        class_weight='balanced_subsample',
        random_state=42,
        n_jobs=-1
    )
    model.fit(X_resampled, y_resampled)
    
    # 保存模型和标准化器
    joblib.dump(model, 'eth_user_classifier.pkl')
    joblib.dump(scaler, 'eth_scaler.pkl')
    print("模型和标准化器已保存")

# --------------------------
# 预测函数（实际使用部分）
# --------------------------
class ETHUserClassifier:
    def __init__(self):
        self.model = joblib.load('eth_user_classifier.pkl')
        self.scaler = joblib.load('eth_scaler.pkl')
        self.features = [
            'balance_ether', 
            'total_transactions', 
            'sent', 
            'received',
            'n_contracts_sent', 
            'n_contracts_received'
        ]
        
    def predict(self, user_data):
        """
        输入参数示例：
        user_data = {
            'balance_ether': 15.2,
            'total_transactions': 238,
            'sent': 120,
            'received': 118,
            'n_contracts_sent': 45,
            'n_contracts_received': 32
        }
        """
        # 转换为DataFrame
        input_df = pd.DataFrame([user_data])
        
        # 检查特征完整性
        missing_features = set(self.features) - set(input_df.columns)
        if missing_features:
            raise ValueError(f"缺少必要特征字段：{missing_features}")
        
        # 排序特征
        input_df = input_df[self.features]
        
        # 处理缺失值（中位数填充）
        input_df = input_df.fillna(input_df.median())
        
        # 标准化
        scaled_data = self.scaler.transform(input_df)   
        
        # 预测
        prediction = self.model.predict(scaled_data)
        probability = self.model.predict_proba(scaled_data)[:, 1]
        
        return {
            'is_professional': bool(prediction[0]),
            'probability': round(float(probability[0]), 4),
            'feature_importance': dict(zip(self.features, self.model.feature_importances_))
        }

# --------------------------
# 使用示例
# --------------------------
if __name__ == "__main__":
    # 首次运行需要训练并保存模型
    #train_and_save_model()
    
    # 初始化分类器
    classifier = ETHUserClassifier()
    
    # 模拟用户输入数据
    test_user = {
            'balance_ether': 1500000.2,
            'total_transactions': 2380000,
            'sent': 1200000,
            'received': 1180000,
            'n_contracts_sent': 4500,
            'n_contracts_received': 3200
        }
    
    # 进行预测
    try:
        result = classifier.predict(test_user)
        print("\n预测结果：")
        print(f"是否专业用户：{'是' if result['is_professional'] else '否'}")
        print(f"专业概率：{result['probability']:.2%}")
        print("\n特征重要性：")
        for feat, imp in sorted(result['feature_importance'].items(), key=lambda x: x[1], reverse=True):
            print(f"{feat:20}：{imp:.4f}")
    except Exception as e:
        print(f"预测失败：{str(e)}")
