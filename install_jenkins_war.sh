#!/bin/bash
set -e

# ---------------------------------------------------------
# 이 스크립트는 Rocky Linux 8 환경에 Jenkins (war 방식)를 설치하고,
# 사용자 정의 포트(기본값: 1015)로 실행되도록 설정합니다.
# - Java 17 및 firewall 설정 포함
# - systemd 유닛 등록 및 자동 실행 설정
# - 설치 완료 후 초기 관리자 비밀번호 출력
# ---------------------------------------------------------

# ===== 사용자 설정 =====
JENKINS_PORT=1015

# [1] 필수 패키지 설치
echo "[1] 필수 패키지 설치 중..."
sudo dnf install -y java-17-openjdk curl firewalld

# [2] Jenkins 전용 사용자 생성
echo "[2] Jenkins 전용 사용자 생성 중..."
sudo useradd -r -m -d /var/lib/jenkins -s /bin/bash jenkins || echo "jenkins 계정 이미 존재"

# [3] Jenkins 디렉토리 생성
echo "[3] Jenkins 실행 경로 생성 중..."
sudo mkdir -p /usr/lib/jenkins
sudo chown -R jenkins:jenkins /usr/lib/jenkins

# [4] 최신 LTS Jenkins WAR 파일 다운로드
echo "[4] Jenkins LTS war 파일 다운로드 중..."
sudo curl -L -o /usr/lib/jenkins/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war
sudo chmod 755 /usr/lib/jenkins/jenkins.war
sudo chown jenkins:jenkins /usr/lib/jenkins/jenkins.war

# [5] systemd 서비스 유닛 생성
echo "[5] Jenkins systemd 서비스 파일 생성 중..."
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins (manual war)
After=network.target

[Service]
Type=simple
User=jenkins
Group=jenkins
WorkingDirectory=/var/lib/jenkins
ExecStart=/usr/bin/java -jar /usr/lib/jenkins/jenkins.war --httpPort=${JENKINS_PORT}
Restart=always
Environment="JENKINS_HOME=/var/lib/jenkins"

[Install]
WantedBy=multi-user.target
EOF

# [6] 방화벽 오픈
echo "[6] 방화벽 ${JENKINS_PORT}/tcp 포트 오픈 중..."
sudo systemctl enable firewalld --now
sudo firewall-cmd --permanent --add-port=${JENKINS_PORT}/tcp
sudo firewall-cmd --reload

# [7] Jenkins 시작
echo "[7] Jenkins 서비스 시작 중..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# [8] 상태 확인
sleep 3
echo "[8] Jenkins 상태 확인:"
sudo systemctl status jenkins --no-pager

# [9] 초기 관리자 비밀번호 출력
echo "[9] 초기 관리자 비밀번호 (initialAdminPassword):"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "초기 비밀번호 파일을 찾을 수 없습니다"
