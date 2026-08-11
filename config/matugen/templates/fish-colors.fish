
# --- Syntax highlighting ---
set -g fish_color_normal              {{ colors.on_background.default.hex_stripped }}
set -g fish_color_command             {{ colors.tertiary.default.hex_stripped }}
set -g fish_color_keyword             {{ colors.secondary.default.hex_stripped }}
set -g fish_color_quote               {{ colors.secondary_container.default.hex_stripped }}
set -g fish_color_redirection         {{ colors.info.default.hex_stripped }}
set -g fish_color_end                 {{ colors.outline_variant.default.hex_stripped }}
set -g fish_color_error               {{ colors.error.default.hex_stripped }} --underline
set -g fish_color_param               {{ colors.on_background.default.hex_stripped }}
set -g fish_color_color_comment       {{ colors.surface_container_high.default.hex_stripped }}
set -g fish_color_operator            {{ colors.warning.default.hex_stripped }}
set -g fish_color_escape              {{ colors.info.default.hex_stripped }}
set -g fish_color_cancel              {{ colors.error.default.hex_stripped }}
set -g fish_color_history_current     {{ colors.secondary.default.hex_stripped }} --bold
set -g fish_color_valid_path          {{ colors.on_background.default.hex_stripped }} --underline
set -g fish_color_autosuggestion      {{ colors.outline_variant.default.hex_stripped }}
set -g fish_color_selection           white --background={{ colors.surface.default.hex_stripped }}
set -g fish_color_search_match        {{ colors.on_background.default.hex_stripped }} --background={{ colors.surface.default.hex_stripped }}

# --- Pager (tab completions) ---
set -g fish_pager_color_completion            {{ colors.on_background.default.hex_stripped }}
set -g fish_pager_color_description           {{ colors.outline_variant.default.hex_stripped }} --italics
set -g fish_pager_color_prefix                {{ colors.tertiary.default.hex_stripped }} --bold --underline
set -g fish_pager_color_progress              {{ colors.outline_variant.default.hex_stripped }} --italics
set -g fish_pager_color_secondary_completion  {{ colors.on_background.default.hex_stripped }} --background={{ colors.surface_container.default.hex_stripped }}
set -g fish_pager_color_secondary_description {{ colors.outline_variant.default.hex_stripped }} --italics --background={{ colors.surface_container.default.hex_stripped }}
set -g fish_pager_color_secondary_prefix      {{ colors.tertiary.default.hex_stripped }} --bold
set -g fish_pager_selected_completion         {{ colors.background.default.hex_stripped }} --background={{ colors.primary.default.hex_stripped }}
set -g fish_pager_selected_description        {{ colors.background.default.hex_stripped }} --background={{ colors.primary.default.hex_stripped }} --italics
set -g fish_pager_selected_prefix             {{ colors.background.default.hex_stripped }} --background={{ colors.primary.default.hex_stripped }} --bold