---
sidebar_position: 2
title: Architecture
---

# Platform Architecture

## Overview

The PMS (Portfolio Management System) is built on a modern, cloud-native microservices architecture designed for high-performance financial data processing, real-time analytics, and enterprise-grade reliability. This document provides a comprehensive view of the platform's architectural design, component interactions, and technical implementation.

## Architectural Principles

### Design Philosophy

- **Microservices**: Independent, loosely-coupled services with clear boundaries
- **Event-Driven**: Asynchronous communication for scalability and resilience
- **Cloud-Native**: Containerized deployment with Kubernetes orchestration
- **GitOps**: Declarative infrastructure and application management
- **Security-First**: Defense-in-depth approach with comprehensive security controls

### Quality Attributes

- **Performance**: Sub-millisecond latency for critical trading operations
- **Scalability**: Horizontal scaling to handle 10,000+ trades per second
- **Reliability**: 99.9% uptime with automated failover and recovery
- **Observability**: Comprehensive monitoring, logging, and tracing
- **Security**: End-to-end encryption, RBAC, and audit logging

## System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Web[Web Browser<br/>Angular SPA]
        Mobile[Mobile Apps<br/>Future]
        API[External APIs<br/>REST/WebSocket]
    end

    subgraph "Edge Layer"
        ALB[AWS ALB<br/>Load Balancer]
        WAF[AWS WAF<br/>Web Firewall]
        CloudFront[CloudFront CDN<br/>Static Assets]
    end

    subgraph "API Gateway Layer"
        Gateway[API Gateway<br/>Spring Cloud Gateway]
        Auth[Auth Service<br/>JWT/OAuth2]
    end

    subgraph "Application Layer"
        TradeCapture[Trade Capture<br/>Ingestion]
        Validation[Validation<br/>Compliance]
        Transactional[Transactional<br/>Settlement]
        Analytics[Analytics<br/>P&L/Risk]
        RTTM[RTTM<br/>Real-Time Monitoring]
        Simulation[Simulation<br/>Modeling]
        Portfolio[Portfolio<br/>Management]
        Leaderboard[Leaderboard<br/>Performance]
    end

    subgraph "Data Layer"
        Postgres[(PostgreSQL<br/>Primary DB)]
        Redis[(Redis<br/>Cache)]
        Kafka[Kafka<br/>Event Streaming]
        RabbitMQ[RabbitMQ<br/>Message Queue]
        S3[(S3<br/>Object Storage)]
    end

    subgraph "Infrastructure Layer"
        EKS[EKS Cluster<br/>Kubernetes]
        RDS[RDS PostgreSQL<br/>Managed DB]
        ElastiCache[ElastiCache Redis<br/>Managed Cache]
        MSK[MSK Kafka<br/>Managed Streaming]
        ECR[ECR<br/>Container Registry]
    end

    subgraph "Supporting Services"
        ArgoCD[ArgoCD<br/>GitOps]
        ESO[External Secrets<br/>Operator]
        Prometheus[Prometheus<br/>Metrics]
        Grafana[Grafana<br/>Dashboards]
        ELK[ELK Stack<br/>Logging]
    end

    Web --> CloudFront
    CloudFront --> ALB
    ALB --> Gateway
    Gateway --> Auth
    Auth --> Application Layer

    Application Layer --> Postgres
    Application Layer --> Redis
    Application Layer --> Kafka
    Application Layer --> RabbitMQ

    EKS --> RDS
    EKS --> ElastiCache
    EKS --> MSK

    ArgoCD --> EKS
    ESO --> EKS
    Prometheus --> EKS
    Grafana --> Prometheus
    ELK --> EKS
```

## Component Architecture

### 1. Client Layer

#### Web Application (Angular SPA)

- **Technology**: Angular 21, TypeScript, RxJS
- **Features**:
  - Real-time portfolio dashboards
  - Trade monitoring and analytics
  - WebSocket connections for live updates
  - JWT-based authentication
- **Deployment**: Static hosting on CloudFront/S3

#### API Clients

- **REST APIs**: Standard HTTP/HTTPS endpoints
- **WebSocket**: STOMP over SockJS for real-time data
- **Authentication**: Bearer token (JWT) in headers

### 2. Edge Layer

#### AWS Application Load Balancer (ALB)

- **Purpose**: External traffic routing and SSL termination
- **Features**:
  - Layer 7 routing based on path/host
  - SSL/TLS termination with AWS Certificate Manager
  - Health checks and automatic failover
  - Integration with AWS WAF

#### AWS WAF (Web Application Firewall)

- **Purpose**: Protection against common web exploits
- **Rules**:
  - SQL injection prevention
  - Cross-site scripting (XSS) protection
  - Rate limiting and bot protection
  - Custom rules for financial data protection

#### CloudFront CDN

- **Purpose**: Global content delivery for static assets
- **Features**:
  - Edge caching for improved performance
  - DDoS protection via AWS Shield
  - SSL/TLS at edge locations

### 3. API Gateway Layer

#### API Gateway Service

- **Technology**: Spring Cloud Gateway
- **Features**:
  - Centralized routing and rate limiting
  - Request/response transformation
  - Circuit breaker patterns
  - CORS handling
- **Configuration**:
  - Routes defined per service
  - Authentication middleware
  - Request logging and metrics

#### Authentication Service

- **Technology**: Spring Boot with Spring Security
- **Features**:
  - JWT token generation and validation
  - OAuth2 integration capabilities
  - User session management
  - Role-based access control (RBAC)
- **Integration**: Redis for session storage

### 4. Application Layer

#### Core Business Services

##### Trade Capture Service

- **Purpose**: High-performance trade data ingestion
- **Technology**: Spring Boot, Spring Integration
- **Responsibilities**:
  - Real-time trade feed processing
  - Data normalization and enrichment
  - Event publishing to Kafka
  - Batch processing capabilities
- **Performance**: 10,000+ trades per second
- **Dependencies**: PostgreSQL, Redis, Kafka, RabbitMQ

##### Validation Service

- **Purpose**: Real-time trade validation and compliance
- **Technology**: Spring Boot, Drools (business rules)
- **Responsibilities**:
  - Business rule validation
  - Market data cross-referencing
  - Compliance checking
  - Invalid trade handling
- **Caching**: Redis for validation rules and market data
- **Dependencies**: PostgreSQL, Redis, Kafka

##### Transactional Service

- **Purpose**: Trade settlement and position management
- **Technology**: Spring Boot, Spring Data JPA
- **Responsibilities**:
  - Trade settlement processing
  - Position updates and reconciliation
  - Transaction logging and audit
  - Financial calculations
- **Dependencies**: PostgreSQL, Kafka

##### Analytics Service

- **Purpose**: Portfolio analytics and risk management
- **Technology**: Spring Boot, Spring Data JPA
- **Responsibilities**:
  - Real-time P&L calculations
  - Risk metrics computation
  - Portfolio performance analysis
  - Sector and market analysis
- **Caching**: Redis for computed results
- **Dependencies**: PostgreSQL, Redis, Kafka

##### RTTM (Real-Time Trade Monitoring)

- **Purpose**: Live position monitoring and alerting
- **Technology**: Spring Boot, WebSocket
- **Responsibilities**:
  - Real-time position tracking
  - Alert generation and notification
  - Threshold monitoring
  - WebSocket broadcasting
- **Dependencies**: PostgreSQL, Redis, Kafka

##### Simulation Service

- **Purpose**: Portfolio simulation and backtesting
- **Technology**: Spring Boot, Python integration
- **Responsibilities**:
  - Monte Carlo simulations
  - Scenario analysis
  - Backtesting strategies
  - Risk modeling
- **Dependencies**: PostgreSQL, RabbitMQ, Kafka

##### Portfolio Service

- **Purpose**: Portfolio management operations
- **Technology**: Spring Boot
- **Responsibilities**:
  - Portfolio CRUD operations
  - Position management
  - Allocation strategies
  - Rebalancing logic
- **Dependencies**: PostgreSQL

##### Leaderboard Service

- **Purpose**: Performance ranking and analytics
- **Technology**: Spring Boot
- **Responsibilities**:
  - Performance calculations
  - Ranking algorithms
  - Competitive analytics
  - Benchmarking
- **Dependencies**: PostgreSQL

### 5. Data Layer

#### PostgreSQL (Primary Database)

- **Purpose**: Transactional and analytical data storage
- **Configuration**:
  - PostgreSQL 16 with PostGIS extensions
  - Multi-AZ deployment for high availability
  - Automated backups and point-in-time recovery
- **Schema Design**:
  - Normalized relational schema
  - Partitioned tables for time-series data
  - Indexes optimized for query patterns
- **Access Pattern**: Connection pooling with HikariCP

#### Redis (Cache Layer)

- **Purpose**: High-performance caching and session storage
- **Configuration**:
  - Redis 7.x with clustering
  - Persistence enabled for data durability
  - Sentinel for high availability
- **Usage Patterns**:
  - Session storage (JWT tokens, user context)
  - Validation rule caching
  - Computed analytics results
  - Rate limiting data

#### Apache Kafka (Event Streaming)

- **Purpose**: Asynchronous inter-service communication
- **Configuration**:
  - Multi-broker cluster with ZooKeeper
  - Schema Registry for message validation
  - Topic partitioning for scalability
- **Key Topics**:
  - `raw-trades`: Incoming trade data
  - `valid-trades`: Validated trade events
  - `invalid-trades`: Rejected trade events
  - `portfolio-updates`: Position changes
  - `analytics-events`: Analytical data updates

#### RabbitMQ (Message Queue)

- **Purpose**: Workflow processing and job queues
- **Configuration**:
  - Clustering with mirrored queues
  - Stream plugin for high-throughput scenarios
  - Dead letter exchanges for error handling
- **Usage**: Batch processing, scheduled jobs, workflow orchestration

#### Amazon S3 (Object Storage)

- **Purpose**: Archival storage and large file handling
- **Usage**:
  - Trade data archives
  - Report generation outputs
  - Backup files
  - Static asset storage

### 6. Infrastructure Layer

#### Amazon EKS (Kubernetes)

- **Purpose**: Container orchestration and management
- **Configuration**:
  - Multi-AZ node groups
  - Auto-scaling based on resource utilization
  - Network policies for security
  - Service mesh integration (Istio - planned)

#### AWS Managed Services

- **RDS PostgreSQL**: Managed relational database
- **ElastiCache Redis**: Managed Redis service
- **MSK (Managed Streaming for Kafka)**: Managed Kafka service
- **ECR**: Container image registry

### 7. Supporting Services

#### ArgoCD (GitOps)

- **Purpose**: Continuous deployment and GitOps
- **Features**:
  - Declarative application management
  - Automated sync from Git repositories
  - Rollback capabilities
  - Multi-environment support

#### External Secrets Operator (ESO)

- **Purpose**: Kubernetes-native secret management
- **Integration**: AWS Secrets Manager synchronization
- **Security**: IRSA (IAM Roles for Service Accounts)

#### Monitoring Stack

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **ELK Stack**: Centralized logging and analysis
- **Jaeger/Tempo**: Distributed tracing

## Communication Patterns

### Synchronous Communication

- **REST APIs**: Standard request/response patterns
- **GraphQL**: Complex data fetching (planned)
- **Health Checks**: Kubernetes readiness/liveness probes

### Asynchronous Communication

- **Event Streaming**: Kafka for inter-service events
- **Message Queues**: RabbitMQ for workflow processing
- **WebSockets**: Real-time client updates

### Data Consistency

- **Eventual Consistency**: Accepted for analytical data
- **Strong Consistency**: Required for transactional data
- **Saga Pattern**: Distributed transaction management
- **Outbox Pattern**: Reliable event publishing

## Security Architecture

### Authentication & Authorization

- **JWT Tokens**: Stateless authentication
- **OAuth2**: External identity provider integration
- **RBAC**: Role-based access control
- **API Keys**: Service-to-service authentication

### Network Security

- **VPC Isolation**: Private subnets for workloads
- **Security Groups**: Least-privilege access controls
- **Network Policies**: Kubernetes network segmentation
- **TLS Everywhere**: End-to-end encryption

### Data Protection

- **Encryption at Rest**: Database and storage encryption
- **Encryption in Transit**: TLS 1.3 for all communications
- **Secret Management**: AWS Secrets Manager with rotation
- **Data Classification**: Sensitive data handling procedures

### Compliance

- **Audit Logging**: Comprehensive audit trails
- **GDPR Compliance**: Data privacy and consent management
- **SOC 2**: Security and availability controls
- **PCI DSS**: Payment data handling (if applicable)

## Deployment Architecture

### GitOps Workflow

1. **Code Changes**: Developers push to Git repositories
2. **CI Pipeline**: Automated testing and image building
3. **ArgoCD Sync**: Automatic deployment to environments
4. **Verification**: Health checks and integration tests
5. **Promotion**: Manual approval for production deployment

### Environment Strategy

- **Development**: Full stack with development optimizations
- **Staging**: Production-like environment for testing
- **Production**: High-availability, multi-AZ deployment

### Infrastructure as Code

- **Terraform**: Cloud infrastructure provisioning
- **Kustomize**: Kubernetes manifest templating
- **Helm**: Package management and versioning

## Scalability & Performance

### Horizontal Scaling

- **Application Services**: Kubernetes HPA based on CPU/memory
- **Database**: Read replicas and connection pooling
- **Cache**: Redis clustering for distributed caching
- **Message Broker**: Kafka partitioning and consumer groups

### Performance Optimization

- **Caching Strategy**: Multi-level caching (application, Redis, CDN)
- **Database Optimization**: Query optimization and indexing
- **Async Processing**: Event-driven architecture for decoupling
- **CDN Integration**: Global content delivery

### Capacity Planning

- **Load Testing**: Regular performance testing
- **Auto-scaling**: Resource-based scaling policies
- **Monitoring**: Real-time performance metrics
- **Alerting**: Proactive capacity management

## Observability & Monitoring

### Metrics Collection

- **Application Metrics**: Business KPIs and performance indicators
- **Infrastructure Metrics**: Resource utilization and health
- **Custom Metrics**: Domain-specific measurements

### Logging Strategy

- **Structured Logging**: JSON format with correlation IDs
- **Log Aggregation**: ELK stack for centralized logging
- **Log Retention**: Configurable retention policies
- **Log Analysis**: Automated anomaly detection

### Distributed Tracing

- **Request Tracing**: End-to-end request tracking
- **Performance Analysis**: Bottleneck identification
- **Error Correlation**: Root cause analysis

### Alerting & Incident Response

- **Multi-level Alerting**: Technical and business alerts
- **Escalation Policies**: Automated alert routing
- **Runbooks**: Automated remediation procedures
- **Post-mortems**: Incident analysis and prevention

## Disaster Recovery

### Backup Strategy

- **Database Backups**: Automated snapshots with retention
- **Configuration Backups**: Infrastructure as code versioning
- **Application Backups**: Container image immutability

### Recovery Procedures

- **RTO/RPO**: Defined recovery time/point objectives
- **Failover**: Automated failover for critical components
- **Data Recovery**: Point-in-time recovery capabilities
- **Testing**: Regular disaster recovery testing

### Business Continuity

- **Multi-Region**: Cross-region replication (planned)
- **Service Dependencies**: Impact analysis and mitigation
- **Communication**: Stakeholder notification procedures

This architecture document serves as the foundation for understanding the PMS platform's design and implementation. All architectural decisions are made with scalability, reliability, and security as primary considerations.
