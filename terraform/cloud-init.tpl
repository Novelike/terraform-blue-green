#cloud-config
runcmd:
  - apt-get update
  - apt-get install -y git python3 python3-venv
  - mkdir -p /opt/app
  - cd /opt/app
  - git clone https://github.com/fastapi/full-stack-fastapi-template.git .
  - python3 -m venv venv
  - . venv/bin/activate
  - pip install -r requirements.txt
  - echo "$(date)" > /opt/deploy_timestamp.txt
  # /hello 엔드포인트 동적 추가 (간단 패치)
  - sed -i '/include_router/docs_router/i\
@app.get("/hello")\
async def hello():\
    return {"deployed": open("/opt/deploy_timestamp.txt").read().strip()}' backend/app/main.py
  - cd backend
  - nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 &

