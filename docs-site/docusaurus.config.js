const {themes: prismThemes} = require('prism-react-renderer');

const config = {
  title: 'Invariant',
  tagline: 'Evidence-backed AI-assisted engineering',
  url: process.env.DOCS_SITE_URL || 'http://localhost',
  baseUrl: process.env.DOCS_BASE_URL || '/',
  trailingSlash: false,
  onBrokenLinks: 'throw',
  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],
  presets: [
    [
      'classic',
      {
        docs: {
          path: '../docs',
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
          breadcrumbs: true,
          showLastUpdateAuthor: false,
          showLastUpdateTime: false,
        },
        blog: false,
        pages: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'INVARIANT',
      hideOnScroll: false,
      items: [
        {type: 'docSidebar', sidebarId: 'docsSidebar', position: 'left', label: 'Docs'},
        {to: '/status', label: 'Status', position: 'left'},
        {to: '/architecture/system-map', label: 'Architecture', position: 'left'},
        {to: '/roadmap/', label: 'Roadmap', position: 'left'},
        {
          href: 'https://github.com/jenksed/invariant-system',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'System',
          items: [
            {label: 'Current status', to: '/status'},
            {label: 'Product boundaries', to: '/architecture/product-boundaries'},
            {label: 'Repository Recon', to: '/workflows/repository-recon'},
          ],
        },
        {
          title: 'Build',
          items: [
            {label: 'Getting started', to: '/getting-started/'},
            {label: 'Development', to: '/development/'},
            {label: 'Roadmap', to: '/roadmap/'},
          ],
        },
      ],
      copyright: `Invariant documentation · repository truth over presentation`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'json', 'yaml', 'elixir'],
    },
  },
};

module.exports = config;
