<?php
#ddev-generated

/**
 * Detects the project's configured ssh-shell and rewrites the
 * Drupal.org CLI Dockerfile to install the matching completion script.
 *
 * The shell is read from the x-ddev.ssh-shell field on the `web` service
 * across all .ddev/docker-compose.*.yaml files, as documented at
 * https://docs.ddev.com/en/stable/users/extend/in-container-configuration/.
 * If no override is present, DDEV defaults to bash.
 *
 * Run as a post_install_actions step from install.yaml; the working
 * directory is the project's .ddev/ folder.
 */

$shell = 'bash';
foreach (glob('docker-compose.*.yaml') ?: [] as $file) {
    $data = @yaml_parse_file($file);
    if (!is_array($data)) {
        continue;
    }
    $candidate = $data['services']['web']['x-ddev']['ssh-shell'] ?? null;
    if (is_string($candidate) && $candidate !== '') {
        $shell = $candidate;
        break;
    }
}

$completion = [
    'bash' => [
        'url'  => 'https://raw.githubusercontent.com/mglaman/drupalorg-cli/main/drupalorg-cli-completion.bash',
        'path' => '/etc/bash_completion.d/drupalorg',
    ],
    'zsh' => [
        'url'  => 'https://raw.githubusercontent.com/mglaman/drupalorg-cli/main/drupalorg-cli-completion.zsh',
        'path' => '/usr/local/share/zsh/site-functions/_drupalorg',
    ],
];

$dockerfile = "#ddev-generated\n"
    . "# Installs the Drupal.org CLI (https://github.com/mglaman/drupalorg-cli) globally\n"
    . "# in the web container. Shell completion target: {$shell}.\n"
    . "#\n"
    . "# The PHAR is fetched at image build time. To pick up a new upstream release,\n"
    . "# rebuild the web image: `ddev debug refresh` or `ddev restart`. To switch the\n"
    . "# completion script after changing ssh-shell, re-run\n"
    . "# `ddev add-on get e0ipso/ddev-drupalorg-cli`.\n"
    . "\n"
    . "RUN set -eux; \\\n"
    . "    curl -fsSL -o /usr/local/bin/drupalorg \\\n"
    . "      https://github.com/mglaman/drupalorg-cli/releases/latest/download/drupalorg.phar; \\\n"
    . "    chmod +x /usr/local/bin/drupalorg\n";

if (isset($completion[$shell])) {
    $url  = $completion[$shell]['url'];
    $path = $completion[$shell]['path'];
    $dir  = dirname($path);
    $dockerfile .= "\n"
        . "RUN set -eux; \\\n"
        . "    mkdir -p {$dir}; \\\n"
        . "    curl -fsSL -o {$path} \\\n"
        . "      {$url}\n";
} else {
    $dockerfile .= "\n# No upstream completion script available for shell '{$shell}'; skipping.\n";
}

$target = 'web-build/Dockerfile.drupalorg-cli';
if (file_put_contents($target, $dockerfile) === false) {
    fwrite(STDERR, "drupalorg-cli: failed to write {$target}\n");
    exit(1);
}

echo "drupalorg-cli: configured shell completion for '{$shell}'.\n";
