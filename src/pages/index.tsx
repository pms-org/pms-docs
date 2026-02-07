import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Welcome`}
      description="PMS Platform Documentation">
      <HomepageHeader />
      <main>
        <div className="container margin-vert--lg">
          <div className="row">
            <div className="col col--4">
              <h3>🏗️ Platform Architecture</h3>
              <p>
                Learn about the PMS platform architecture, security model, and core concepts.
              </p>
              <Link to="/docs/platform/overview">Explore Platform →</Link>
            </div>
            <div className="col col--4">
              <h3>🔧 Services</h3>
              <p>
                Detailed documentation for all platform services including auth, analytics, and more.
              </p>
              <Link to="/docs/services/auth/overview">View Services →</Link>
            </div>
            <div className="col col--4">
              <h3>⚙️ Operations</h3>
              <p>
                Deployment guides, monitoring, debugging, and operational runbooks.
              </p>
              <Link to="/docs/operations/deployment-guide">Read Operations →</Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
