# Papra

## 功能特性

- 文档归档与管理
- 全文搜索
- 标签分类
- 文档预览
- 多用户支持
- 默认中文界面

## 快速部署

```bash
docker run -d \
  -p 1221:1221 \
  -v $(pwd)/data:/app/app-data \
  --name papra-zh \
  wsng911/papra-zh:latest
```

访问 `http://localhost:1221`
