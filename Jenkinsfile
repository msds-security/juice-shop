pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        CLUSTER_NAME       = 'juice-shop-cluster'
        NAMESPACE          = 'juice-shop'
        DEPLOYMENT_NAME    = 'juice-shop'
        AWS_ACCOUNT_ID     = '562517367791'
        ECR_REPO           = 'juice-shop'
        ECR_REGISTRY       = '562517367791.dkr.ecr.us-east-2.amazonaws.com'
        IMAGE_TAG          = "${BUILD_NUMBER}"
        GIT_REPO           = 'https://github.com/msds-security/juice-shop'
    }

    stages {

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "--- AWS CLI ---"
                    aws --version
                    echo "--- kubectl ---"
                    kubectl version --client
                    echo "--- Docker ---"
                    docker --version
                    echo "--- Wiz CLI ---"
                    wizcli version
                    echo "--- AWS Identity ---"
                    aws sts get-caller-identity
                '''
            }
        }

        stage('Checkout Source') {
            steps {
                git branch: 'main',
                    url: "${GIT_REPO}"
            }
        }

        stage('Wiz IaC Scan') {
            steps {
                sh '''
                    echo "Running Wiz IaC scan on source code..."
                    wizcli iac scan \
                        --client-id ${WIZ_CLIENT_ID} \
                        --client-secret ${WIZ_CLIENT_SECRET} \
                        --path . \
                        --format human || true
                '''
            }
        }

        stage('Wiz Source Code Scan') {
            steps {
                sh '''
                    echo "Running Wiz source code and secrets scan..."
                    wizcli dir scan \
                        --client-id ${WIZ_CLIENT_ID} \
                        --client-secret ${WIZ_CLIENT_SECRET} \
                        --path . \
                        --format human || true
                '''
            }
        }

        stage('Create ECR Repository') {
            steps {
                sh '''
                    echo "Creating ECR repo if it does not exist..."
                    aws ecr describe-repositories \
                        --repository-names ${ECR_REPO} \
                        --region ${AWS_DEFAULT_REGION} > /dev/null 2>&1 || \
                    aws ecr create-repository \
                        --repository-name ${ECR_REPO} \
                        --region ${AWS_DEFAULT_REGION}
                    echo "ECR repo ready: ${ECR_REGISTRY}/${ECR_REPO}"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest
                    echo "Image built: ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                '''
            }
        }

        stage('Wiz Image Scan') {
            steps {
                sh '''
                    echo "Running Wiz container image scan..."
                    wizcli scan container-image \
                        --client-id ${WIZ_CLIENT_ID} \
                        --client-secret ${WIZ_CLIENT_SECRET} \
                        ${ECR_REPO}:${IMAGE_TAG} \
                        --format human || true
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    echo "Logging in to ECR..."
                    aws ecr get-login-password \
                        --region ${AWS_DEFAULT_REGION} | \
                    docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}
                    echo "Pushing image to ECR..."
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
                    echo "Push complete: ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                '''
            }
        }

        stage('Configure kubectl') {
            steps {
                sh '''
                    echo "Updating kubeconfig for cluster: ${CLUSTER_NAME}"
                    aws eks update-kubeconfig \
                        --name ${CLUSTER_NAME} \
                        --region ${AWS_DEFAULT_REGION}
                    kubectl get nodes
                '''
            }
        }

        stage('Create Namespace') {
            steps {
                sh '''
                    kubectl get namespace ${NAMESPACE} || \
                        kubectl create namespace ${NAMESPACE}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "Deploying ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} to EKS..."
                    if kubectl get deployment ${DEPLOYMENT_NAME} -n ${NAMESPACE} > /dev/null 2>&1; then
                        echo "Updating existing deployment with new image..."
                        kubectl set image deployment/${DEPLOYMENT_NAME} \
                            ${DEPLOYMENT_NAME}=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} \
                            -n ${NAMESPACE}
                    else
                        echo "Creating new deployment..."
                        kubectl create deployment ${DEPLOYMENT_NAME} \
                            --image=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} \
                            --namespace=${NAMESPACE}
                    fi
                '''
            }
        }

        stage('Expose Service') {
            steps {
                sh '''
                    if kubectl get svc ${DEPLOYMENT_NAME} -n ${NAMESPACE} > /dev/null 2>&1; then
                        echo "Service already exists — skipping..."
                    else
                        kubectl expose deployment ${DEPLOYMENT_NAME} \
                            --type=LoadBalancer \
                            --port=80 \
                            --target-port=3000 \
                            --namespace=${NAMESPACE}
                    fi
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Waiting for rollout to complete..."
                    kubectl rollout status deployment/${DEPLOYMENT_NAME} \
                        -n ${NAMESPACE} \
                        --timeout=300s
                    echo "--- Pods ---"
                    kubectl get pods -n ${NAMESPACE}
                    echo "--- Service ---"
                    kubectl get svc -n ${NAMESPACE}
                '''
            }
        }

        stage('Get Public URL') {
            steps {
                sh '''
                    echo "Fetching LoadBalancer URL..."
                    for i in $(seq 1 12); do
                        URL=$(kubectl get svc ${DEPLOYMENT_NAME} -n ${NAMESPACE} \
                            --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                        if [ -n "$URL" ]; then
                            echo "✅ Juice Shop is live at: http://${URL}"
                            break
                        fi
                        echo "Waiting for LoadBalancer... attempt $i/12"
                        sleep 15
                    done
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Full Wiz-scanned build and deploy to juice-shop-cluster in us-east-2 succeeded!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above for details.'
        }
        always {
            sh 'docker rmi ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} || true'
        }
    }
}
