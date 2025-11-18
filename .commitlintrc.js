module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Allow chart scope in commit messages (e.g., feat(acapy): ...)
    'scope-enum': [0],
    // Type must be one of these
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Code style (formatting, etc)
        'refactor', // Code refactoring
        'perf',     // Performance improvement
        'test',     // Tests
        'chore',    // Maintenance
        'ci',       // CI/CD changes
        'build',    // Build system changes
        'revert',   // Revert a previous commit
      ],
    ],
    // Subject should not be empty
    'subject-empty': [2, 'never'],
    // Subject should not end with period
    'subject-full-stop': [2, 'never', '.'],
    // Subject should be lowercase (conventional commits standard)
    'subject-case': [2, 'always', 'lower-case'],
  },
};
