module.exports = {
  branches: ["main", "master"],
  ci: false,
  plugins: [
    ["@semantic-release/commit-analyzer", {
      preset: "conventionalcommits",
      releaseRules: [
        { type: "docs", release: "patch" },
        { type: "chore", release: "patch" },
        { type: "refactor", release: "patch" }
      ],
      parserOpts: {
        headerPattern: /^(\w*)(?:\(([^\)]*)\))?\:\s*(.*)$/,
        headerCorrespondence: ['type', 'scope', 'subject']
      }
    }],
    ["@semantic-release/release-notes-generator", {
      preset: "conventionalcommits",
      parserOpts: {
        headerPattern: /^(\w*)(?:\(([^\)]*)\))?\:\s*(.*)$/,
        headerCorrespondence: ['type', 'scope', 'subject']
      },
      writerOpts: {
        committerDate: false,
        groupBy: 'type',
        commitGroupsSort: 'title',
        commitsSort: ['scope', 'subject'],
        noteGroupsSort: 'title',
        commitPartial: '{{#if scope}}**{{scope}}:** {{/if}}{{subject}} ([{{shortHash}}]({{url}})){{#if body}}\n\n### âš  Full Commit Details\n\n{{body}}{{/if}}',
        transform: (commit, context) => {
          const types = {
            feat: 'âœ¨ New Features',
            fix: 'ðŸ› Bug Fixes',
            docs: 'ðŸ“š Documentation Changes',
            perf: 'âš¡ Performance Improvements',
            refactor: 'â™»ï¸ Code Refactoring',
            test: 'ðŸ§ª Tests',
            build: 'ðŸ—ï¸ Build System',
            ci: 'ðŸ‘· Continuous Integration',
            chore: 'ðŸ”§ Chores',
            style: 'ðŸ’„ Styles',
            revert: 'âª Reverts'
          };

          if (commit.type && types[commit.type]) {
            commit.type = types[commit.type];
          }
          // Ensure proper commit link generation
          if (!commit.hash) return commit;

          // Set the shortHash for display and URL for linking
          commit.shortHash = commit.hash.slice(0, 7);
          commit.url = `https://github.com/${context.owner}/${context.repository}/commit/${commit.hash}`;

          // Clean up commit subject - remove empty parentheses and trailing spaces
          if (commit.subject) {
            commit.subject = commit.subject.replace(/\s*\(\)\s*$/, '').trim();
          }

          if (commit.body) {
            // Clean up commit body - remove empty parentheses
            commit.body = commit.body.replace(/\s*\(\)\s*$/gm, '').trim();
          }
          return commit;
        }
      }
    }],
    ["@semantic-release/changelog", {
      changelogFile: "CHANGELOG.md",
      changelogTitle: "# Changelog\n\nAll notable changes to this project will be documented in this file."
    }],
    ["@semantic-release/git", {
      assets: ["CHANGELOG.md"],
      message: "chore(release): version ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }],
    ["@semantic-release/github", {
      successComment: "This ${issue.pull_request ? 'PR is included' : 'issue has been resolved'} in version ${nextRelease.version} ðŸŽ‰",
      labels: false,
      releasedLabels: false
    }]
  ]
};
