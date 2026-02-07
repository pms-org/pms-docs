import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Platform',
      collapsed: false,
      items: [
        'platform/overview',
        'platform/architecture',
        'platform/ingress-and-networking',
        'platform/security-model',
        'platform/authentication-flow',
        'platform/configuration-management',
        'platform/environments',
      ],
    },
    {
      type: 'category',
      label: 'Services',
      collapsed: false,
      items: [
        {
          type: 'category',
          label: 'Auth Service',
          items: [
            'services/auth/overview',
            'services/auth/api-contract',
            'services/auth/security',
            'services/auth/deployment',
            'services/auth/failure-modes',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Frontend',
      collapsed: false,
      items: [
        'frontend/overview',
        'frontend/configuration',
        'frontend/auth-integration',
        'frontend/websocket-integration',
        'frontend/common-issues',
      ],
    },
    {
      type: 'category',
      label: 'Infrastructure',
      collapsed: false,
      items: [
        'infrastructure/eks',
        'infrastructure/ingress',
        'infrastructure/networking',
        'infrastructure/secrets-management',
        'infrastructure/scaling-and-upgrades',
      ],
    },
    {
      type: 'category',
      label: 'Operations',
      collapsed: false,
      items: [
        'operations/deployment-guide',
        'operations/monitoring',
        'operations/debugging',
        'operations/runbooks',
        'operations/incident-response',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      collapsed: false,
      items: [
        'reference/endpoints',
        'reference/ports-and-protocols',
        'reference/glossary',
      ],
    },
  ],
};

export default sidebars;
