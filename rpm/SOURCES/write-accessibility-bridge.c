#include <gtk/gtk.h>

gboolean write_test_get_extents(GtkAccessibleText *text, guint start, guint end,
                               graphene_rect_t *extents)
{
    return GTK_ACCESSIBLE_TEXT_GET_IFACE(text)->get_extents(text, start, end, extents);
}
