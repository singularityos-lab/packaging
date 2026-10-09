using Write;
using Write.Test;

[CCode (cname = "write_test_get_extents")]
extern bool text_extents(Gtk.AccessibleText text, uint start, uint end, out Graphene.Rect rect);

int main(string[] args) {
    Gtk.init();
    var d = Document.create_blank();
    d.body.clear();
    var first = new Paragraph.with_text("A\u00e9 B");
    var second = new Paragraph.with_text("Second line");
    d.body.add(first);
    d.body.add(second);
    var ed = new Editor(d);
    var view = new Singularity.Apps.WriteDocView();
    view.set_document(d, ed);
    view.relayout_now();

    check(view.set_caret_position(2), "set a caret after a Unicode character");
    check(ed.focus.para == first && ed.focus.offset == 2, "caret offsets count characters");
    check_int((int) view.get_caret_position(), 2, "caret position round trip");
    var range = Gtk.AccessibleTextRange();
    range.start = 3;
    range.length = 5;
    check(view.set_selection(0, range), "select across paragraphs");
    check(ed.anchor.para == first && ed.anchor.offset == 3 && ed.focus.para == second && ed.focus.offset == 3, "selection maps both endpoints");
    Gtk.AccessibleTextRange[] ranges;
    check(view.get_selection(out ranges) && ranges.length == 1 && ranges[0].start == 3 && ranges[0].length == 5, "selection round trip");
    check(!view.set_selection(1, range), "reject a second selection");
    range.start = size_t.MAX;
    range.length = 1;
    check(!view.set_selection(0, range), "reject overflowing ranges");
    check(!view.set_caret_position(uint.MAX), "reject an offset past the document");
    check(view.set_caret_position(2), "clear selection through caret setter");
    check(!ed.has_selection, "caret setter clears selection");

    var rect = Graphene.Rect();
    check(text_extents(view, 0, 4, out rect) && rect.size.width > 0 && rect.size.height > 0, "text range has geometry");
    float height = rect.size.height;
    check(text_extents(view, 0, 5, out rect) && rect.size.height == height, "exclusive paragraph boundary stays on the first line");
    check(text_extents(view, 0, 6, out rect) && rect.size.height > height, "cross paragraph geometry spans both lines");
    check(text_extents(view, 2, 2, out rect) && rect.size.width == 1, "empty range uses caret geometry");
    var point = Graphene.Point();
    point.x = rect.origin.x;
    point.y = rect.origin.y + rect.size.height / 2;
    uint offset;
    check(view.get_offset(point, out offset) && offset == 2, "caret geometry maps back to the Unicode offset");
    check(!text_extents(view, 8, 3, out rect), "reject reversed ranges");
    string[] names, values;
    view.get_default_attributes(out names, out values);
    check(names.length == values.length, "default attributes remain paired");
    return finish("write-accessibility");
}
