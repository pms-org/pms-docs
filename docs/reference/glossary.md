---
sidebar_position: 3
title: Glossary
---

---

sidebar_position: 3
title: Glossary

---

# Glossary

## A

**API Gateway**: A service that acts as a single entry point for all client requests to backend services. In PMS, it handles routing, authentication, rate limiting, and request/response transformation.

**Application Load Balancer (ALB)**: AWS load balancer that operates at the application layer (Layer 7) and routes traffic based on HTTP/HTTPS request content.

**AWS Certificate Manager (ACM)**: AWS service for provisioning, managing, and deploying SSL/TLS certificates for use with AWS services.

**AWS Elastic Kubernetes Service (EKS)**: Managed Kubernetes service that runs Kubernetes clusters on AWS without needing to install or maintain Kubernetes control plane.

**AWS Secrets Manager**: AWS service for securely storing and retrieving secrets such as database credentials, API keys, and other sensitive information.

## B

**Bearer Token**: A type of access token used in OAuth 2.0 where the token is included in the Authorization header as "Bearer &lt;token&gt;".

**Blue-Green Deployment**: A deployment strategy where two identical environments (blue and green) are maintained, allowing for zero-downtime deployments by switching traffic between them.

**Business Domain**: A specific area of business knowledge or activity. In microservices architecture, services are often aligned with business domains.

## C

**Circuit Breaker**: A design pattern that prevents cascading failures by stopping requests to a failing service and providing fallback responses.

**Cloud-Native**: An approach to building and running applications that takes full advantage of cloud computing delivery models, typically involving containers, microservices, and orchestration.

**CQRS (Command Query Responsibility Segregation)**: An architectural pattern that separates read and write operations into different models to optimize performance and scalability.

**Container**: A lightweight, standalone, executable package that includes everything needed to run a piece of software, including code, runtime, libraries, and settings.

## D

**Database Schema**: The structure of a database described in a formal language, including tables, columns, relationships, and constraints.

**Domain-Driven Design (DDD)**: An approach to software development that centers the development on programming a domain model that has a rich understanding of the processes and rules of a domain.

**Docker**: A platform for developing, shipping, and running applications in containers.

## E

**Elastic Load Balancing (ELB)**: AWS service that automatically distributes incoming application traffic across multiple targets, such as EC2 instances, containers, and IP addresses.

**Event Sourcing**: An architectural pattern where state changes are logged as a sequence of events that can be replayed to reconstruct the current state.

**Eventual Consistency**: A consistency model used in distributed computing to achieve high availability where data may be temporarily inconsistent but will become consistent over time.

## F

**Fault Tolerance**: The ability of a system to continue operating properly in the event of failure of some of its components.

**Frontend**: The user-facing part of a web application that users interact with directly, typically built with HTML, CSS, and JavaScript frameworks like React.

## H

**Helm**: A package manager for Kubernetes that helps define, install, and upgrade complex Kubernetes applications.

**High Availability (HA)**: A system's ability to operate continuously without failure for a long time, typically achieved through redundancy and failover mechanisms.

**Horizontal Pod Autoscaling (HPA)**: Kubernetes feature that automatically scales the number of pod replicas based on observed CPU utilization or other metrics.

## I

**Infrastructure as Code (IaC)**: The process of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

**Ingress**: A Kubernetes resource that manages external access to services in a cluster, typically HTTP/HTTPS traffic.

**Istio**: An open-source service mesh that provides traffic management, observability, and security for microservices.

## J

**Java Spring Boot**: A framework for creating stand-alone, production-grade Spring-based applications with minimal configuration.

**JSON Web Token (JWT)**: An open standard for securely transmitting information between parties as a JSON object, commonly used for authentication and authorization.

## K

**Kubernetes**: An open-source container orchestration platform for automating deployment, scaling, and management of containerized applications.

**Kustomize**: A Kubernetes native configuration management tool that allows customization of raw, template-free YAML files.

## L

**Load Balancer**: A device or service that distributes network traffic across multiple servers to ensure no single server becomes overwhelmed.

**Log Aggregation**: The process of collecting, processing, and storing log data from multiple sources in a centralized location for analysis.

## M

**Microservices**: An architectural style that structures an application as a collection of small, independent services that communicate over well-defined APIs.

**Monitoring**: The process of observing and checking the health and performance of systems, applications, and infrastructure components.

## N

**Namespace**: A Kubernetes object that provides a scope for names, allowing resources to be grouped and isolated within a cluster.

**Network Load Balancer (NLB)**: AWS load balancer that operates at the transport layer (Layer 4) and routes traffic based on IP protocol data.

## O

**OAuth 2.0**: An authorization framework that enables applications to obtain limited access to user accounts on an HTTP service.

**Observability**: The ability to measure the internal state of a system by examining its outputs, including logs, metrics, and traces.

**OpenAPI Specification**: A standard for describing REST APIs, allowing both humans and computers to understand the capabilities of a service.

## P

**Pod**: The smallest deployable unit in Kubernetes, consisting of one or more containers that share storage and network resources.

**Portfolio**: A collection of financial assets held by an investor, such as stocks, bonds, and other securities.

**PostgreSQL**: An open-source relational database management system known for its robustness, extensibility, and standards compliance.

**Prometheus**: An open-source monitoring and alerting toolkit designed for reliability and scalability.

## R

**Rate Limiting**: A technique to control the rate of requests sent or received by a network interface controller.

**Reactive Programming**: A programming paradigm oriented around data flows and the propagation of change, commonly used for handling asynchronous data streams.

**Redis**: An open-source, in-memory data structure store used as a database, cache, and message broker.

**Relational Database Management System (RDBMS)**: A database management system based on the relational model, where data is stored in tables with relationships between them.

**Replica**: A copy of a pod or database instance used for load balancing, failover, or backup purposes.

**Representational State Transfer (REST)**: An architectural style for designing networked applications, based on stateless communication between client and server.

**Resilience**: The ability of a system to withstand and recover from disruptive events, including hardware failures, network issues, and unexpected load.

## S

**Saga Pattern**: A design pattern for managing distributed transactions in microservices, where each service performs its operation and publishes an event for the next service.

**Scalability**: The ability of a system to handle increased load by adding resources to the system.

**Security Group**: A virtual firewall for EC2 instances and other AWS resources that controls inbound and outbound traffic.

**Service Discovery**: The automatic detection of services and their locations in a distributed system.

**Service Mesh**: A dedicated infrastructure layer for handling service-to-service communication, providing features like load balancing, service discovery, and security.

**Session Management**: The process of securely handling user sessions in web applications, including creation, maintenance, and termination.

**Sidecar Pattern**: A design pattern where a secondary container (sidecar) is deployed alongside the main application container to provide additional functionality.

**Spring Cloud Gateway**: A library for building API gateways on top of Spring WebFlux, providing routing, filtering, and other gateway features.

**Spring Security**: A powerful and highly customizable authentication and access-control framework for Java applications.

## T

**Terraform**: An open-source infrastructure as code software tool that allows users to define and provision data center infrastructure using a declarative configuration language.

**Token Type**: In PMS, refers to USER tokens (for end-user authentication) and SERVICE tokens (for service-to-service communication).

**Tracing**: The process of tracking requests as they flow through distributed systems, helping to identify performance bottlenecks and failures.

## V

**Virtual Private Cloud (VPC)**: A virtual network dedicated to an AWS account, providing isolation and security for AWS resources.

**Volume**: A directory containing data, accessible to the containers in a pod, that persists beyond the life of a container.

## W

**WebSocket**: A computer communications protocol that provides full-duplex communication channels over a single TCP connection, commonly used for real-time web applications.

**Webhook**: A mechanism for one system to notify another system about events, typically through HTTP POST requests.

## Z

**Zero Downtime Deployment**: A deployment strategy that allows applications to be updated without any service interruption to end users.
