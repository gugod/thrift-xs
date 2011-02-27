MODULE = Thrift::XS   PACKAGE = Thrift::XS::BinaryProtocol

SV *
new(char *klass, SV *transport)
CODE:
{
  TBinaryProtocol *p;
  New(0, p, sizeof(TBinaryProtocol), TBinaryProtocol);
  New(0, p->last_fields, sizeof(struct fieldq), struct fieldq);

  if (sv_isa(transport, "Thrift::XS::MemoryBuffer"))
    p->mbuf = (TMemoryBuffer *)xs_object_magic_get_struct_rv_pretty(aTHX_ transport, "mbuf");
  else
    p->mbuf = NULL;
    
  p->transport = transport;
  
  p->bool_type     = -1;
  p->bool_id       = -1;
  p->bool_value_id = -1;
  p->last_field_id = 0;
  
  SIMPLEQ_INIT(p->last_fields);

  RETVAL = xs_object_magic_create(
    aTHX_
    (void *)p,
    gv_stashpv(klass, 0)
  );
}
OUTPUT:
  RETVAL

void
writeMessageBegin(TBinaryProtocol *p, SV *name, int type, int seqid)
CODE:
{
  DEBUG_TRACE("writeMessageBegin()\n");
  
  SV *namecopy = sv_mortalcopy(name); // because we can't modify the original name
  sv_utf8_encode(namecopy);
  int namelen = sv_len(namecopy);
  SV *data = sv_2mortal(newSV(8 + namelen));
  char i32[4];
  
  // i32 type
  type = VERSION_1 | type;
  INT_TO_I32(i32, type, 0);
  sv_setpvn(data, i32, 4);
  
  // i32 len + string
  INT_TO_I32(i32, namelen, 0);
  sv_catpvn(data, i32, 4);
  sv_catsv(data, namecopy);
  
  // i32 seqid
  INT_TO_I32(i32, seqid, 0);
  sv_catpvn(data, i32, 4);
  
  WRITE_SV(p, data);
}

void
writeMessageEnd(SV *)
CODE:
{ }

void
writeStructBegin(SV *, SV *)
CODE:
{ }

void
writeStructEnd(SV *)
CODE:
{ }

void
writeFieldBegin(TBinaryProtocol *p, SV * /*name*/, int type, int id)
CODE:
{
  DEBUG_TRACE("writeFieldBegin(type %d, id %d)\n", type, id);
  char data[3];
  
  data[0] = type & 0xff;      // byte
  data[1] = (id >> 8) & 0xff; // i16
  data[2] = id & 0xff;
  
  WRITE(p, data, 3);
}

void
writeFieldEnd(SV *)
CODE:
{ }

void
writeFieldStop(TBinaryProtocol *p)
CODE:
{
  DEBUG_TRACE("writeFieldStop()\n");
  
  char data[1];
  data[0] = T_STOP;
  
  WRITE(p, data, 1);
}

void
writeMapBegin(TBinaryProtocol *p, int keytype, int valtype, int size)
CODE:
{
  DEBUG_TRACE("writeMapBegin(keytype %d, valtype %d, size %d)\n", keytype, valtype, size);
  char data[6];
  
  data[0] = keytype & 0xff;
  data[1] = valtype & 0xff;
  INT_TO_I32(data, size, 2);

  WRITE(p, data, 6);
}

void
writeMapEnd(SV *)
CODE:
{ }

void
writeListBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeListBegin(elemtype %d, size %d)\n", elemtype, size);
  char data[5];
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(p, data, 5);
}

void
writeListEnd(SV *)
CODE:
{ }

void
writeSetBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeSetBegin(elemtype %d, size %d)\n", elemtype, size);
  char data[5];
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(p, data, 5);
}

void
writeSetEnd(SV *)
CODE:
{ }

void
writeBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeBool(%d)\n", SvTRUE(value) ? 1 : 0);
  char data[1];
  
  data[0] = SvTRUE(value) ? 1 : 0;
  
  WRITE(p, data, 1);
}

void
writeByte(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeByte(%d)\n", SvIV(value) & 0xff);
  char data[1];
  
  data[0] = SvIV(value) & 0xff;
  
  WRITE(p, data, 1);
}

void
writeI16(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI16(%d)\n", value);
  char data[2];
  
  INT_TO_I16(data, value, 0);
  
  WRITE(p, data, 2);
}

void
writeI32(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI32(%d)\n", value);
  char data[4];
  
  INT_TO_I32(data, value, 0);
  
  WRITE(p, data, 4);
}

void
writeI64(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeI64(%lld)\n", (int64_t)SvNV(value));
  char data[8];
  int64_t i64 = (int64_t)SvNV(value);
  
  data[7] = i64 & 0xff;
  data[6] = (i64 >> 8) & 0xff;
  data[5] = (i64 >> 16) & 0xff;
  data[4] = (i64 >> 24) & 0xff;
  data[3] = (i64 >> 32) & 0xff;
  data[2] = (i64 >> 40) & 0xff;
  data[1] = (i64 >> 48) & 0xff;
  data[0] = (i64 >> 56) & 0xff;
  
  WRITE(p, data, 8);
}

void
writeDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeDouble(%f)\n", (double)SvNV(value));
  char data[8];
  union {
    double d;
    int64_t i;
  } u;
  
  u.d = (double)SvNV(value);

  data[7] = u.i & 0xff;
  data[6] = (u.i >> 8) & 0xff;
  data[5] = (u.i >> 16) & 0xff;
  data[4] = (u.i >> 24) & 0xff;
  data[3] = (u.i >> 32) & 0xff;
  data[2] = (u.i >> 40) & 0xff;
  data[1] = (u.i >> 48) & 0xff;
  data[0] = (u.i >> 56) & 0xff;
  
  WRITE(p, data, 8);
}

void
writeString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeString(%s)\n", SvPVX(value));
  
  SV *valuecopy = sv_mortalcopy(value);
  sv_utf8_encode(valuecopy);
  int len = sv_len(valuecopy);
  SV *data = sv_2mortal(newSV(4 + len));
  char i32[4];
  
  INT_TO_I32(i32, len, 0);
  sv_setpvn(data, i32, 4);
  sv_catsv(data, valuecopy);
  
  WRITE_SV(p, data);
}

void
readMessageBegin(TBinaryProtocol *p, SV *name, SV *type, SV *seqid)
CODE:
{
  DEBUG_TRACE("readMessageBegin()\n");
  
  SV *tmp;
  int version;
  char *tmps;
  
  // read version + type
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(version, tmps, 0);
  
  if (version < 0) {
    if ((version & VERSION_MASK) != VERSION_1) {
      THROW("Thrift::TException", "Missing version identifier");
    }
    // set type
    if (SvROK(type))
      sv_setiv(SvRV(type), version & 0x000000ff);
    
    // read string
    {
      int len;
      READ_SV(p, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(len, tmps, 0);
      if (len) {
        READ_SV(p, tmp, len);
        sv_utf8_decode(tmp);
        if (SvROK(name))
          sv_setsv(SvRV(name), tmp);
      }
      else {
        if (SvROK(name))
          sv_setpv(SvRV(name), "");
      }
    }
    
    // read seqid
    {
      int s;
      READ_SV(p, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(s, tmps, 0);
      if (SvROK(seqid))
        sv_setiv(SvRV(seqid), s);
    }
  }
  else {
    THROW("Thrift::TException", "Missing version identifier");
  }
}

void
readMessageEnd(SV *)
CODE:
{ }

void
readStructBegin(SV *, SV *name)
CODE:
{
  DEBUG_TRACE("readStructBegin()\n");
  
  if (SvROK(name))
    sv_setpv(SvRV(name), "");
}

void
readStructEnd(SV *)
CODE:
{ }

void
readFieldBegin(TBinaryProtocol *p, SV * /*name*/, SV *fieldtype, SV *fieldid)
CODE:
{
  DEBUG_TRACE("readFieldBegin()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  
  // fieldtype byte
  if (SvROK(fieldtype))
    sv_setiv(SvRV(fieldtype), tmps[0]);
  
  if (tmps[0] == T_STOP) {
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), 0);
    XSRETURN_EMPTY;
  }
  
  // fieldid i16
  {
    READ_SV(p, tmp, 2);
    tmps = SvPVX(tmp);
    int fid;
    I16_TO_INT(fid, tmps, 0);
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), fid);
  }
}

void
readFieldEnd(SV *)
CODE:
{ }

void
readMapBegin(TBinaryProtocol *p, SV *keytype, SV *valtype, SV *size)
CODE:
{
  DEBUG_TRACE("readMapBegin()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 6);
  tmps = SvPVX(tmp);
  
  // keytype byte
  if (SvROK(keytype))
    sv_setiv(SvRV(keytype), tmps[0]);
  
  // valtype byte
  if (SvROK(valtype))
    sv_setiv(SvRV(valtype), tmps[1]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 2);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readMapEnd(SV *)
CODE:
{ }

void
readListBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readListBegin()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 5);
  tmps = SvPVX(tmp);
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readListEnd(SV *)
CODE:
{ }

void
readSetBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readSetBegin()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 5);
  tmps = SvPVX(tmp);
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readSetEnd(SV *)
CODE:
{ }

void
readBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readBool()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0] ? 1 : 0);
}

void
readByte(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readByte()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0]);
}

void
readI16(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI16()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 2);
  tmps = SvPVX(tmp);
  
  int v;
  I16_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}

void
readI32(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI32()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  
  int v;
  I32_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}

void
readI64(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI64()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 8);
  tmps = SvPVX(tmp);
  
  uint64_t hi;
  uint32_t lo;
  I32_TO_INT(hi, tmps, 0);
  I32_TO_INT(lo, tmps, 4);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), (hi << 32) | lo);
}

void
readDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readDouble()\n");
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 8);
  tmps = SvPVX(tmp);
  
  uint64_t hi;
  uint32_t lo;
  I32_TO_INT(hi, tmps, 0);
  I32_TO_INT(lo, tmps, 4);

  union {
    double d;
    int64_t i;
  } u;  
  u.i = (hi << 32) | lo;
  
  if (SvROK(value))
    sv_setnv(SvRV(value), u.d);
}

void
readString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readString()\n");
  SV *tmp;
  char *tmps;
  
  int len;
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(len, tmps, 0);
  if (len) {
    READ_SV(p, tmp, len);
    sv_utf8_decode(tmp);
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}

void
readStringBody(TBinaryProtocol *p, SV *value, int len)
CODE:
{
  // This method is never used but is here for compat
  SV *tmp;
  
  if (len) {
    READ_SV(p, tmp, len);
    sv_utf8_decode(tmp);
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}
